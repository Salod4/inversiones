# frozen_string_literal: true

require "bigdecimal"

module TransferParamHelpers
  extend ActiveSupport::Concern

  private

  def destination_entries_from_params(transfer_params)
    raw_entries = transfer_params[:destination_entries]
    entries =
      if raw_entries.is_a?(ActionController::Parameters)
        raw_entries.values
      else
        Array(raw_entries)
      end

    parsed = entries.filter_map do |entry|
      next unless entry
      to_ref = entry[:to_entity_ref].presence || entry["to_entity_ref"].presence
      amount = entry[:amount].presence || entry["amount"].presence
      next unless to_ref && amount
      { to_entity_ref: to_ref, amount: BigDecimal(amount.to_s) }
    end

    if parsed.empty? && transfer_params[:to_entity_ref].present? && transfer_params[:amount].present?
      parsed << {
        to_entity_ref: transfer_params[:to_entity_ref],
        amount: BigDecimal(transfer_params[:amount].to_s)
      }
    end

    parsed
  end

  def assign_entities_from_refs(transfer, from_ref:, to_ref:)
    apply_ref_to_transfer(transfer, :from, from_ref)
    apply_ref_to_transfer(transfer, :to, to_ref)
  end

  def apply_ref_to_transfer(transfer, prefix, ref)
    return if ref.blank?
    type, token = ref.to_s.split(":", 2)
    return unless Transfer::ALLOWED_ENTITY_TYPES.include?(type) || type == Transfer::DESTINATION_CASH_BOX

    if type == "CustomerGroup"
      transfer.send("#{prefix}_entity_type=", "CustomerGroup")
      transfer.send("#{prefix}_entity_id=", nil)
      transfer.send("#{prefix}_group=", token)
      return
    elsif type == "Other"
      transfer.send("#{prefix}_entity_type=", "Other")
      transfer.send("#{prefix}_entity_id=", nil)
      transfer.send("#{prefix}_group=", nil)
      return
    elsif type == Transfer::DESTINATION_CASH_BOX
      transfer.send("#{prefix}_entity_type=", Transfer::DESTINATION_CASH_BOX)
      transfer.send("#{prefix}_entity_id=", nil)
      transfer.send("#{prefix}_group=", nil)
      return
    end

    entity = resolve_entity_ref(type, token)
    transfer.send("#{prefix}_group=", nil)
    transfer.send("#{prefix}_entity=", entity) if entity
  end

  def resolve_entity_ref(type, id)
    return nil unless id.present?
    case type
    when "Customer" then Customer.find_by(id: id)
    when "Supplier" then Supplier.find_by(id: id)
    when "User" then User.find_by(id: id)
    when Transfer::DESTINATION_CASH_BOX then nil
    end
  end

  def entity_ref_for(transfer, side)
    type = transfer.send("#{side}_entity_type")
    if type == "CustomerGroup"
      group = transfer.send("#{side}_group")
      return "CustomerGroup:#{group}" if group.present?
    elsif type == "Other"
      return "Other"
    elsif type.present? && transfer.send("#{side}_entity_id").present?
      return "#{type}:#{transfer.send("#{side}_entity_id")}"
    end
    nil
  end

  def prefill_destination_entries(transfer)
    to_ref = entity_ref_for(transfer, :to)
    return [] unless to_ref || transfer.amount.present?
    [ { to_entity_ref: to_ref, amount: transfer.amount } ]
  end

  def available_balance_for_batch(transfer, sale)
    return sale.available_transfer_amount(excluding: nil) if sale.present?
    from_entity = transfer.send(:safe_entity, :from)
    case from_entity
    when Customer
      from_entity.available_transfer_total
    when Supplier
      from_entity.available_transfer_total
    else
      nil
    end
  end

  def persist_destination_batch(base_attrs:, destination_entries:, from_ref:, sale:, builder:)
    template = builder.call
    template.assign_attributes(base_attrs)
    assign_entities_from_refs(template, from_ref: from_ref, to_ref: destination_entries.first&.dig(:to_entity_ref))

    if destination_entries.empty?
      template.errors.add(:base, "Agrega al menos un destino")
      return [ [], template ]
    end

    cash_box_amount = BigDecimal(base_attrs[:cash_box_amount].to_s.presence || "0")
    total_amount = destination_entries.sum { |d| d[:amount].to_d } + cash_box_amount
    available = available_balance_for_batch(template, sale)
    if available && total_amount > available
      template.errors.add(:base, "El monto total (#{total_amount.to_s("F")}) supera el saldo disponible de #{available.to_s("F")}")
      return [ [], template ]
    end

    created = []
    Transfer.transaction do
      destination_entries.each do |dest|
        transfer = builder.call
        transfer.assign_attributes(base_attrs)
        assign_entities_from_refs(transfer, from_ref: from_ref, to_ref: dest[:to_entity_ref])
        transfer.amount = dest[:amount]
        transfer.save!
        created << transfer
      end
    end

    [ created, nil ]
  rescue ActiveRecord::RecordInvalid => e
    [ [], e.record ]
  end
end
