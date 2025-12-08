class TransfersController < ApplicationController
  before_action :set_transfer, only: [ :show, :edit, :update, :destroy ]
  before_action :set_sale, only: [ :index, :new, :create ]
  before_action :set_entities, only: [ :new, :create, :edit, :update ]

  def index
    scope = if @sale
      @sale.transfers
    else
      Transfer.includes(:sale, :customer, :supplier)
    end
    @pagy, @transfers = pagy(scope.order(occurred_at: :desc))
  end

  def show
    @sale = @transfer.sale
  end

  def new
    if @sale
      @transfer = @sale.transfers.build(customer: @sale.customer, supplier: @sale.supplier)
      @transfer.from_entity = @sale.customer
      @transfer.to_entity = @sale.supplier
    else
      @transfer = Transfer.new
    end
  end

  def edit
    @sale = @transfer.sale
  end

  def create
    @transfer = (@sale ? @sale.transfers.build : Transfer.new)
    assign_entities_from_params(@transfer)
    @transfer.assign_attributes(transfer_params.except(:from_entity_ref, :to_entity_ref))
    if @sale
      @transfer.customer ||= @sale.customer
      @transfer.supplier ||= @sale.supplier
    end
    if @transfer.save
      redirect_to(@sale ? sale_transfers_path(@sale) : transfers_path, notice: "Transfer was successfully created.")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @sale = @transfer.sale
    assign_entities_from_params(@transfer)
    if @transfer.update(transfer_params.except(:from_entity_ref, :to_entity_ref))
      redirect_to transfer_path(@transfer), notice: "Transfer was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    sale = @transfer.sale
    if @transfer.destroy
      redirect_to(sale ? sale_transfers_path(sale) : transfers_path, notice: "Transfer was successfully destroyed.")
    else
      redirect_to(sale ? sale_transfers_path(sale) : transfers_path, alert: @transfer.errors.full_messages.to_sentence)
    end
  end

  private

  def set_sale
    @sale = Sale.find_by(id: params[:sale_id])
  end

  def set_transfer
    @transfer = Transfer.find(params[:id])
  end

  def set_entities
    current_sale = @sale || @transfer&.sale
    supplier = current_sale&.supplier || @transfer&.supplier
    @suppliers = supplier ? [ supplier ] : Supplier.order(:name)
    @customers = Customer.order(:name)
    @users = User.order(:name)
  end

  def transfer_params
    params.require(:transfer).permit(
      :code,
      :occurred_at,
      :supplier_id,
      :amount,
      :note,
      :from_entity_ref,
      :to_entity_ref
    )
  end

  def assign_entities_from_params(transfer)
    from_ref = transfer_params[:from_entity_ref]
    to_ref = transfer_params[:to_entity_ref]
    transfer.from_entity = resolve_entity_ref(from_ref) if from_ref.present?
    transfer.to_entity = resolve_entity_ref(to_ref) if to_ref.present?
  end

  def resolve_entity_ref(ref)
    type, id = ref.to_s.split(":")
    return nil unless Transfer::ALLOWED_ENTITY_TYPES.include?(type) && id.present?
    case type
    when "Customer" then Customer.find_by(id: id)
    when "Supplier" then Supplier.find_by(id: id)
    when "User" then User.find_by(id: id)
    end
  end
end
