# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# db/seeds.rb


puts "== Seeding base users =="
jskab = User.find_or_create_by!(email: "jskab@example.com") do |u|
  u.password = "123456"
end
sam = User.find_or_create_by!(email: "sam@example.com") do |u|
  u.password = "123456"
end

def slug_code(str)
  str.to_s.upcase.gsub(/[^A-Z0-9]+/, "_").gsub(/_+$/, "")[0, 30]
end

puts "== Seeding suppliers =="
suppliers_data = [
  { name: "KLEMBA",  code: "KJS",     default_analysis_pct: 0.01   },
  { name: "KLING",   code: "KLING",   default_analysis_pct: 0.01   },
  { name: "BONANZA", code: "BONANZA", default_analysis_pct: 0.012  },
  { name: "LC",      code: "JJS",     default_analysis_pct: 0.0135 },
  { name: "LC2",     code: "JJS_2",   default_analysis_pct: 0.0175 } # si quieres mismo code "JJS", cámbialo y garantizamos unicidad con sufijo
]

supplier_by_name = {}
suppliers_data.each do |s|
  sup = Supplier.find_or_create_by!(code: s[:code]) do |rec|
    rec.name = s[:name]
    rec.default_analysis_pct = s[:default_analysis_pct]
  end
  supplier_by_name[s[:name]] = sup
end

# Helpers para crear cliente y vincularlo a 1+ proveedores
def ensure_customer!(name)
  Customer.find_or_create_by!(code: slug_code(name)) { |c| c.name = name }
end

def link_customer_supplier!(customer, supplier)
  CustomerSupplier.find_or_create_by!(customer: customer, supplier: supplier)
end

puts "== Definición de defaults de comisión (JSKAB / SAM) =="
DEFAULTS = {
  "BONANZA" => { jskab: 0.0067, sam: 0.0003 },  # 0.67% / 0.03%
  "KLEMBA"  => { jskab: 0.0087, sam: 0.0003 }   # 0.87% / 0.03%
}.freeze

# Si algunos clientes tienen override, defínelos aquí por proveedor
# Ejemplos sacados de tu tabla (KLEMBA cambia algunas filas):
OVERRIDES = {
  "BONANZA" => {
    # Ejemplo de overrides en BONANZA (usa 0.42% / 0.03% cuando comisión total 1.75%)
    "MS/MOY"                 => { jskab: 0.0042, sam: 0.0003 },
    "MS/MOY CREATIVIDAD"     => { jskab: 0.0042, sam: 0.0003 },
    "MS/MOY PISOS"           => { jskab: 0.0042, sam: 0.0003 },
    "MS/MOY KEIFI"           => { jskab: 0.0042, sam: 0.0003 },
    "MS/MOY VARIOS"          => { jskab: 0.0042, sam: 0.0003 },
    "MS/MOY LOG"             => { jskab: 0.0042, sam: 0.0003 },
    "MS/MOY SAAD SERV"       => { jskab: 0.0042, sam: 0.0003 },
    "MS/MOY LATI"            => { jskab: 0.0042, sam: 0.0003 },
    "MS/MOY DICON"           => { jskab: 0.0042, sam: 0.0003 },
    "MS/MOY LEV"             => { jskab: 0.0042, sam: 0.0003 },
    # Otros ejemplos de tu primera tabla:
    "FELIPE (SMART)"         => { jskab: 0.00295, sam: 0.0003 }, # 0.295% / 0.03%
    "DAN/CARLOS SANDOVAL"    => { jskab: 0.0117,  sam: 0.0003 }, # 1.17% / 0.03%
    "CHOCHO"                 => { jskab: 0.0167,  sam: 0.0003 }, # 1.67% / 0.03%
    "NADJAR"                 => { jskab: 0.0117,  sam: 0.0003 }, # 1.17% / 0.03%
    "JAR"                    => { jskab: 0.0167,  sam: 0.0003 }, # 1.67% / 0.03%
    "GGL"                    => { jskab: 0.0167,  sam: 0.0003 }, # 1.67% / 0.03%
    "ISMEJU"                 => { jskab: 0.0117,  sam: 0.0003 }, # 1.17% / 0.03%
    "SELOGIN"                => { jskab: 0.0267,  sam: 0.0003 }, # 2.67% / 0.03%
    "BERAL"                  => { jskab: 0.0167,  sam: 0.0003 }, # con DAN/2% total, aquí de tu tabla
    "BENNY SHWARTZ"          => { jskab: 0.0217,  sam: 0.0003 }, # 2.17% / 0.03%
    "ARISTEO"                => { jskab: 0.0367,  sam: 0.0003 }  # 3.67% / 0.03%
  },
  "KLEMBA" => {
    # Misma idea, pero con los valores de la segunda tabla (muchos suben JSKAB a 0.87%)
    "BEHAR/RODIER"           => { jskab: 0.0052,  sam: 0.0003 }, # 0.52% / 0.03%
    "BEHAR/PUNTO"            => { jskab: 0.0052,  sam: 0.0003 },
    "BEHZA"                  => { jskab: 0.0052,  sam: 0.0003 },
    "DAN/CARLOS SANDOVAL"    => { jskab: 0.0137,  sam: 0.0003 }, # 1.37% / 0.03%
    "CHOCHO"                 => { jskab: 0.0187,  sam: 0.0003 }, # 1.87% / 0.03%
    "NADJAR"                 => { jskab: 0.0137,  sam: 0.0003 }, # 1.37% / 0.03%
    "JAR"                    => { jskab: 0.0187,  sam: 0.0003 },
    "GGL"                    => { jskab: 0.0187,  sam: 0.0003 },
    "ISMEJU"                 => { jskab: 0.0137,  sam: 0.0003 },
    "MS/MOY"                 => { jskab: 0.0062,  sam: 0.0003 }, # 0.62% / 0.03%
    "MS/MOY CREATIVIDAD"     => { jskab: 0.0062,  sam: 0.0003 },
    "MS/MOY PISOS"           => { jskab: 0.0062,  sam: 0.0003 },
    "MS/MOY KEIFI"           => { jskab: 0.0062,  sam: 0.0003 },
    "MS/MOY VARIOS"          => { jskab: 0.0062,  sam: 0.0003 },
    "MS/MOY LOG"             => { jskab: 0.0062,  sam: 0.0003 },
    "MS/MOY SAAD SERV"       => { jskab: 0.0062,  sam: 0.0003 },
    "MS/MOY LATI"            => { jskab: 0.0062,  sam: 0.0003 },
    "MS/MOY DICON"           => { jskab: 0.0062,  sam: 0.0003 },
    "MS/MOY LEV"             => { jskab: 0.0062,  sam: 0.0003 },
    "FELIPE (SMART)"         => { jskab: 0.00495, sam: 0.0003 }, # 0.495% / 0.03%
    "BERAL"                  => { jskab: 0.0187,  sam: 0.0003 }, # en la segunda tabla sube
    "BENNY SHWARTZ"          => { jskab: 0.0162,  sam: 0.0003 }, # con CHOCHO/1.75% → 1.62% / 0.03%
    "ARISTEO"                => { jskab: 0.0387,  sam: 0.0003 }  # 3.87% / 0.03%
  }
}.freeze

puts "== Clientes BONANZA =="
bonanza = supplier_by_name["BONANZA"]
bonanza_clients = %w[
  ARQUI ARQUI\ CECY ARQUI\ SIANSHA ARQUI\ ATRI ARQUI\ QUANTON ARQUI\ PAIDI
  ARQUI\ ELIZABETH ARQUI\ HELADERO ARQUI\ RUNOXA ARQUI\ IMAAN ARQUI\ TRX
  ARQUI\ PALMAR ARQUI\ LOYAL ARQUI\ IS\ SA ARQUI\ KURI ARQUI\ EXCELENCIA
  ARQUI\ TO ARQUI\ KOMUNFE ARQUI\ JF ARQUI\ TURQUIE ARQUI\ ACCRETIO
  ARQUI\ CLICK ARQUI\ IGLESIA ARQUI\ STONE ARQUI\ HENTSCHEL ARQUI\ SADOVICH
  ARQUI\ KAEM ARQUI\ LAURA ARQUI\ JAVIER ARQUI\ BETZA ARQUI\ TCI ARQUI\ DELUX
  ARQUI\ PEGALUM ARQUI\ YTZJAK ARQUI\ CESUTEX ARQUI\ VARIOS ARQUI\ ZORKA
  ARQUI\ KAMPAHAUG ARQUI\ JAZAKA ARQUI\ MAGDALENAS ARQUI\ AP ARQUI\ AW
  ARQUI\ VIC ARQUI\ TEURA ARQUI\ BOTONES ARQUI\ RANCHO ARQUI\ ANKA ARQUI\ END
  ARQUI\ PUNTO\ MAR ARQUI\ SALEM ARQUI\ MV ARQUI\ TECHNIFOAM ARQUI\ AGROASEMEX
  ARQUI\ PATRICIA ARQUI\ CESAR ARQUI\ ASE ARQUI\ RIGHT ARQUI\ TMM ARQUI\ VITRAL
  ARQUI\ JUAREZ ARQUI\ POLANCO ARQUI\ EVERARDO ARQUI\ LESCOR ARQUI\ RAGOLI
  ARQUI\ GABY ARQUI\ EDIFICATOP ARQUI\ IMPLEMENTACION ARQUI\ ARGENMEX
  ARQUI\ YOMAJO ARQUI\ EXSAN ARQUI\ LOCOLUXURY ARQUI\ COPPER ARQUI\ OLIMANI
  ARQUI\ MC ARQUI\ GUADALQUIVIR ARQUI\ PINTORES ARQUI\ CARGO ARQUI\ KATY
  ARQUI\ SERTRES ARQUI\ PERMAPLAY ARQUI\ INTERBIZ ARQUI\ HUMANAS ARQUI\ YVONNE
  ARQUI\ EVELYN ARQUI\ IAP ARQUI\ YOROK ARQUI\ MICHELLE ARQUI\ MICHA ARQUI\ VS
  ARQUI\ NT ARQUI\ FIT ARQUI\ CASINO ARQUI\ CTN ARQUI\ MEZCAL ARQUI\ TWM
  ARQUI\ CAMPESTRE ARQUI\ ELLY ARQUI\ MECA ARQUI\ TECHNO ARQUI\ GORPICK
  ARQUI\ LUGA ARQUI\ FERVI ARQUI\ CONSUMIBLES ARQUI\ ARGUELLES ARQUI\ MIRA
  ARQUI\ JURVAD ARQUI\ MIRA-JURVAD ARQUI\ MARSAL ARQUI\ BAJO
  BEHAR/RODIER BEHAR/PUNTO BEHZA
  LEONIDAS LEONIDAS/ROMIX LEONIDAS/VEREDIS LEONIDAS/GERA LEONIDAS/MIRAVALLE
  LEONIDAS/MONARCA LEONIDAS/DAREMI LEONIDAS/ITMM LEONIDAS/ONLH LEONIDAS/BITSDEV
  LEONIDAS/TEAM\ BITS LEONIDAS/ING LEONIDAS/ETI LEONIDAS/BATERIAS LEONIDAS/TOP
  DAN/CARLOS\ SANDOVAL CHOCHO NADJAR NADJAR/RAVER NADJAR/RUBIO
  JAR GGL ISMEJU
  MS/MOY MS/MOY\ CREATIVIDAD MS/MOY\ PISOS MS/MOY\ KEIFI MS/MOY\ VARIOS
  MS/MOY\ LOG MS/MOY\ SAAD\ SERV MS/MOY\ LATI MS/MOY\ DICON MS/MOY\ LEV
  FF/INSCOM FF/LA\ NET MS/BJ MS/MARCOS\ MEX MS/MARCOS\ SHEVA MS/SHEVA
  MS/MARCOS\ 27\ MICRAS
  FELIPE\ (SMART)
  JABOB/SELIMEX JABOB/KALI IAK SAMOSH CHERIZ SELOGIN YOSH PAM
  BERAL BSID BETO\ LIS DAR ADMAS BENNY\ SHWARTZ ZEKE ARISTEO MARMAS AJ MECHY
  SEMAH LOROS KURI PAUL\ HABIB BORIS NICO
  AZUL COSMOS\ F COSMOS\ SPEIS KIKE DUMA MACA
]

puts "== Clientes KLEMBA =="
klemba = supplier_by_name["KLEMBA"]
klemba_clients = %w[
  # Usa la segunda tabla (los mismos nombres que arriba si aplican),
  # pero con los overrides de KLEMBA donde correspondan.
  ARQUI ARQUI\ CECY ARQUI\ SIANSHA ARQUI\ ATRI ARQUI\ QUANTON ARQUI\ PAIDI
  # (... puedes repetir o seleccionar tus clientes de KLEMBA)
  BEHAR/RODIER BEHAR/PUNTO BEHZA
  DAN/CARLOS\ SANDOVAL CHOCHO NADJAR
  MS/MOY MS/MOY\ CREATIVIDAD MS/MOY\ PISOS MS/MOY\ KEIFI
  FELIPE\ (SMART) BERAL BENNY\ SHWARTZ ARISTEO
  AZUL COSMOS\ F COSMOS\ SPEIS KIKE DUMA MACA
]

def create_and_link!(names, supplier, defaults, overrides)
  names.each do |n|
    # des-escapar backslashes visuales
    name = n.gsub("\\", "")
    customer = ensure_customer!(name)
    link_customer_supplier!(customer, supplier)

    # Aquí sólo imprimimos para ver qué default quedaría (no persiste en DB)
    ov = overrides[name]
    jskab_pct = ov&.fetch(:jskab, nil) || defaults[:jskab]
    sam_pct   = ov&.fetch(:sam,   nil) || defaults[:sam]
    puts "  - #{supplier.name} / #{customer.name} => JSKAB=#{jskab_pct} SAM=#{sam_pct}"
  end
end

puts "== Vinculando BONANZA..."
create_and_link!(bonanza_clients, bonanza, DEFAULTS["BONANZA"], OVERRIDES["BONANZA"])

puts "== Vinculando KLEMBA..."
create_and_link!(klemba_clients, klemba, DEFAULTS["KLEMBA"], OVERRIDES["KLEMBA"])

puts "== Listo. Clientes y relaciones creadas. (Los defaults JSKAB/SAM impresos arriba son para que luego los uses al crear ventas)"
