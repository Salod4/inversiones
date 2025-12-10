# frozen_string_literal: true

require "securerandom"

USERS = [
  { key: :jack,  email: "jack@example.com",  name: "Jack",  code: "JACK" },
  { key: :sam,   email: "sam@example.com",   name: "Sam",   code: "SAM" },
  { key: :fondo, email: "fondo@example.com", name: "Fondo", code: "FONDO" },
  { key: :subagent, email: "subagent@example.com", name: "Subagente", code: "SUBAG" }
].freeze

SUPPLIERS = [
  { code: "KJS",     name: "Klemba", default_analysis_pct: 0.0100 },
  { code: "KLING",   name: "Kling",          default_analysis_pct: 0.0100 },
  { code: "BONANZA", name: "Bonanza",        default_analysis_pct: 0.0120 },
  { code: "JJS135",  name: "LC 1.35%",       default_analysis_pct: 0.0135 },
  { code: "JJS175",  name: "LC 1.75%",       default_analysis_pct: 0.0175 }
].freeze

DUMA_SUBCUSTOMERS = [
  "DUMA/BOOPSY",
  "DUMA/HONG",
  "DUMA/MOBILI",
  "DUMA/TRES PUNTOS",
  "DUMA/HEG",
  "DUMA/LOSI",
  "DUMA/REFRICARE",
  "DUMA/FACIL",
  "DUMA/MARVIC",
  "DUMA/PROMOCELA",
  "DUMA/SINERGIA",
  "DUMA/LEAV",
  "DUMA/GAMBOA",
  "DUMA/ARANA",
  "DUMA/SQ",
  "DUMA/JOLER",
  "DUMA/BALVINA",
  "DUMA/PATIÑO",
  "DUMA/PIGMENTOS",
  "DUMA/COTEMAR",
  "DUMA/CRISTEL",
  "DUMA/FABULA",
  "DUMA/VIDEOMAPPING",
  "DUMA/NORA"
].freeze

DUMA_GROUP_CUSTOMERS = ([ "DUMA" ] + DUMA_SUBCUSTOMERS).freeze
DUMA_FEE_DEFAULT = 0.015
DUMA_GROUP_FEES = DUMA_GROUP_CUSTOMERS.to_h { |name| [ name, DUMA_FEE_DEFAULT ] }.freeze

DUMA_SPLITS_BY_SUPPLIER = {
  "KJS" => DUMA_GROUP_CUSTOMERS.to_h { |name| [ name, { fondo: 0.001, jack: 0.002, sam: 0.002 } ] },
  "BONANZA" => DUMA_GROUP_CUSTOMERS.to_h { |name| [ name, { fondo: 0.001, jack: 0.001, sam: 0.001 } ] }
}.freeze

SUPPLIER_ALIASES = {
  "KLING" => "KJS",
  "JJS135" => "KJS",
  "JJS175" => "KJS"
}.freeze

CUSTOMERS_BY_SUPPLIER = {
  "KJS" =>   [
    "ARQUI",
    "ARQUI CECY",
    "ARQUI SIANSHA",
    "ARQUI ATRI",
    "ARQUI QUANTON",
    "ARQUI PAIDI",
    "ARQUI ELIZABETH",
    "ARQUI HELADERO",
    "ARQUI RUNOXA",
    "ARQUI IMAAN",
    "ARQUI TRX",
    "ARQUI PALMAR",
    "ARQUI LOYAL",
    "ARQUI IS SA",
    "ARQUI KURI",
    "ARQUI EXCELENCIA",
    "ARQUI TO",
    "ARQUI KOMUNFE",
    "ARQUI JF",
    "ARQUI TURQUIE",
    "ARQUI ACCRETIO",
    "ARQUI CLICK",
    "ARQUI IGLESIA",
    "ARQUI STONE",
    "ARQUI HENTSCHEL",
    "ARQUI SADOVICH",
    "ARQUI KAEM",
    "ARQUI LAURA",
    "ARQUI JAVIER",
    "ARQUI BETZA",
    "ARQUI TCI",
    "ARQUI DELUX",
    "ARQUI PEGALUM",
    "ARQUI YTZJAK",
    "ARQUI CESUTEX",
    "ARQUI VARIOS",
    "ARQUI ZORKA",
    "ARQUI KAMPAHAUG",
    "ARQUI JAZAKA",
    "ARQUI MAGDALENAS",
    "ARQUI AP",
    "ARQUI AW",
    "ARQUI VIC",
    "ARQUI TEURA",
    "ARQUI BOTONES",
    "ARQUI RANCHO",
    "ARQUI ANKA",
    "ARQUI END",
    "ARQUI PUNTO MAR",
    "ARQUI SALEM",
    "ARQUI MV",
    "ARQUI TECHNIFOAM",
    "ARQUI AGROASEMEX",
    "ARQUI PATRICIA",
    "ARQUI CESAR",
    "ARQUI ASE",
    "ARQUI RIGHT",
    "ARQUI TMM",
    "ARQUI VITRAL",
    "ARQUI JUAREZ",
    "ARQUI POLANCO",
    "ARQUI EVERARDO",
    "ARQUI LESCOR",
    "ARQUI RAGOLI",
    "ARQUI GABY",
    "ARQUI EDIFICATOP",
    "ARQUI IMPLEMENTACION",
    "ARQUI ARGENMEX",
    "ARQUI YOMAJO",
    "ARQUI EXSAN",
    "ARQUI LOCOLUXURY",
    "ARQUI COPPER",
    "ARQUI OLIMANI",
    "ARQUI MC",
    "ARQUI GUADALQUIVIR",
    "ARQUI PINTORES",
    "ARQUI CARGO",
    "ARQUI KATY",
    "ARQUI SERTRES",
    "ARQUI PERMAPLAY",
    "ARQUI INTERBIZ",
    "ARQUI HUMANAS",
    "ARQUI YVONNE",
    "ARQUI EVELYN",
    "ARQUI IAP",
    "ARQUI YOROK",
    "ARQUI MICHELLE",
    "ARQUI MICHA",
    "ARQUI VS",
    "ARQUI NT",
    "ARQUI FIT",
    "ARQUI CASINO",
    "ARQUI CTN",
    "ARQUI MEZCAL",
    "ARQUI TWM",
    "ARQUI CAMPESTRE",
    "ARQUI ELLY",
    "ARQUI MECA",
    "ARQUI TECHNO",
    "ARQUI GORPICK",
    "ARQUI LUGA",
    "ARQUI FERVI",
    "ARQUI CONSUMIBLES",
    "ARQUI ARGUELLES",
    "ARQUI MIRA",
    "ARQUI JURVAD",
    "ARQUI MIRA-JURVAD",
    "ARQUI MARSAL",
    "ARQUI BAJO",
    "BEHAR/RODIER",
    "BEHAR/PUNTO",
    "BEHZA",
    "LEONIDAS",
    "LEONIDAS/ROMIX",
    "LEONIDAS/VEREDIS",
    "LEONIDAS/GERA",
    "LEONIDAS/MIRAVALLE",
    "LEONIDAS/MONARCA",
    "LEONIDAS/DAREMI",
    "LEONIDAS/ITMM",
    "LEONIDAS/ONLH",
    "LEONIDAS/BITSDEV",
    "LEONIDAS/TEAM BITS",
    "LEONIDAS/ING",
    "LEONIDAS/ETI",
    "LEONIDAS/BATERIAS",
    "LEONIDAS/TOP",
    "DAN/CARLOS SANDOVAL",
    "CHOCHO",
    "NADJAR",
    "NADJAR/RAVER",
    "NADJAR/RUBIO",
    "JAR",
    "GGL",
    "ISMEJU",
    "MS/MOY",
    "MS/MOY CREATIVIDAD",
    "MS/MOY PISOS",
    "MS/MOY KEIFI",
    "MS/MOY VARIOS",
    "MS/MOY LOG",
    "MS/MOY SAAD SERV",
    "MS/MOY LATI",
    "MS/MOY DICON",
    "MS/MOY LEV",
    "FF/INSCOM",
    "FF/LA NET",
    "MS/BJ",
    "MS/MARCOS MEX",
    "MS/MARCOS SHEVA",
    "MS/SHEVA",
    "MS/MARCOS 27 MICRAS",
    "FELIPE (SMART)",
    "JABOB/SELIMEX",
    "JABOB/KALI",
    "IAK",
    "SAMOSH",
    "CHERIZ",
    "SELOGIN",
    "YOSH",
    "PAM",
    "BERAL",
    "BSID",
    "BETO LIS",
    "DAR",
    "ADMAS",
    "BENNY SHWARTZ",
    "ZEKE",
    "ARISTEO",
    "MARMAS",
    "AJ",
    "MECHY",
    "SEMAH",
    "LOROS",
    "KURI",
    "PAUL HABIB",
    "BORIS",
    "NICO",
    "AZUL",
    "COSMOS F",
    "COSMOS SPEIS",
    "KIKE",
    "DUMA",
    "MACA"
  ] + DUMA_SUBCUSTOMERS,
  "BONANZA" =>   [
    "ARQUI",
    "ARQUI CECY",
    "ARQUI SIANSHA",
    "ARQUI ATRI",
    "ARQUI QUANTON",
    "ARQUI PAIDI",
    "ARQUI ELIZABETH",
    "ARQUI HELADERO",
    "ARQUI RUNOXA",
    "ARQUI IMAAN",
    "ARQUI TRX",
    "ARQUI PALMAR",
    "ARQUI LOYAL",
    "ARQUI IS SA",
    "ARQUI KURI",
    "ARQUI EXCELENCIA",
    "ARQUI TO",
    "ARQUI KOMUNFE",
    "ARQUI JF",
    "ARQUI TURQUIE",
    "ARQUI ACCRETIO",
    "ARQUI CLICK",
    "ARQUI IGLESIA",
    "ARQUI STONE",
    "ARQUI HENTSCHEL",
    "ARQUI SADOVICH",
    "ARQUI KAEM",
    "ARQUI LAURA",
    "ARQUI JAVIER",
    "ARQUI BETZA",
    "ARQUI TCI",
    "ARQUI DELUX",
    "ARQUI PEGALUM",
    "ARQUI YTZJAK",
    "ARQUI CESUTEX",
    "ARQUI VARIOS",
    "ARQUI ZORKA",
    "ARQUI KAMPAHAUG",
    "ARQUI JAZAKA",
    "ARQUI MAGDALENAS",
    "ARQUI AP",
    "ARQUI AW",
    "ARQUI VIC",
    "ARQUI TEURA",
    "ARQUI BOTONES",
    "ARQUI RANCHO",
    "ARQUI ANKA",
    "ARQUI END",
    "ARQUI PUNTO MAR",
    "ARQUI SALEM",
    "ARQUI MV",
    "ARQUI TECHNIFOAM",
    "ARQUI AGROASEMEX",
    "ARQUI PATRICIA",
    "ARQUI CESAR",
    "ARQUI ASE",
    "ARQUI RIGHT",
    "ARQUI TMM",
    "ARQUI VITRAL",
    "ARQUI JUAREZ",
    "ARQUI POLANCO",
    "ARQUI EVERARDO",
    "ARQUI LESCOR",
    "ARQUI RAGOLI",
    "ARQUI GABY",
    "ARQUI EDIFICATOP",
    "ARQUI IMPLEMENTACION",
    "ARQUI ARGENMEX",
    "ARQUI YOMAJO",
    "ARQUI EXSAN",
    "ARQUI LOCOLUXURY",
    "ARQUI COPPER",
    "ARQUI OLIMANI",
    "ARQUI MC",
    "ARQUI GUADALQUIVIR",
    "ARQUI PINTORES",
    "ARQUI CARGO",
    "ARQUI KATY",
    "ARQUI SERTRES",
    "ARQUI PERMAPLAY",
    "ARQUI INTERBIZ",
    "ARQUI HUMANAS",
    "ARQUI YVONNE",
    "ARQUI EVELYN",
    "ARQUI IAP",
    "ARQUI YOROK",
    "ARQUI MICHELLE",
    "ARQUI MICHA",
    "ARQUI VS",
    "ARQUI NT",
    "ARQUI FIT",
    "ARQUI CASINO",
    "ARQUI CTN",
    "ARQUI MEZCAL",
    "ARQUI TWM",
    "ARQUI CAMPESTRE",
    "ARQUI ELLY",
    "ARQUI MECA",
    "ARQUI TECHNO",
    "ARQUI GORPICK",
    "ARQUI LUGA",
    "ARQUI FERVI",
    "ARQUI CONSUMIBLES",
    "ARQUI ARGUELLES",
    "ARQUI MIRA",
    "ARQUI JURVAD",
    "ARQUI MIRA-JURVAD",
    "ARQUI MARSAL",
    "ARQUI BAJO",
    "ARQUI/END",
    "ARQUI/LANDSOFT",
    "BEHAR/RODIER",
    "BEHAR/PUNTO",
    "BEHZA",
    "LEONIDAS",
    "LEONIDAS/ROMIX",
    "LEONIDAS/VEREDIS",
    "LEONIDAS/GERA",
    "LEONIDAS/MIRAVALLE",
    "LEONIDAS/MONARCA",
    "LEONIDAS/DAREMI",
    "LEONIDAS/ITMM",
    "LEONIDAS/ONLH",
    "LEONIDAS/BITSDEV",
    "LEONIDAS/TEAM BITS",
    "LEONIDAS/ING",
    "LEONIDAS/ETI",
    "LEONIDAS/BATERIAS",
    "LEONIDAS/TOP",
    "DAN/CARLOS SANDOVAL",
    "CHOCHO",
    "NADJAR",
    "NADJAR/RAVER",
    "NADJAR/RUBIO",
    "JAR",
    "GGL",
    "ISMEJU",
    "MS/MOY",
    "MS/MOY CREATIVIDAD",
    "MS/MOY PISOS",
    "MS/MOY KEIFI",
    "MS/MOY VARIOS",
    "MS/MOY LOG",
    "MS/MOY SAAD SERV",
    "MS/MOY LATI",
    "MS/MOY DICON",
    "MS/MOY LEV",
    "FF/INSCOM",
    "FF/LA NET",
    "MS/BJ",
    "MS/MARCOS MEX",
    "MS/MARCOS SHEVA",
    "MS/SHEVA",
    "MS/MARCOS 27 MICRAS",
    "FELIPE (SMART)",
    "JABOB/SELIMEX",
    "JABOB/KALI",
    "IAK",
    "SAMOSH",
    "CHERIZ",
    "SELOGIN",
    "YOSH",
    "PAM",
    "BERAL",
    "BSID",
    "BETO LIS",
    "DAR",
    "ADMAS",
    "BENNY SHWARTZ",
    "ZEKE",
    "ARISTEO",
    "MARMAS",
    "AJ",
    "MECHY",
    "SEMAH",
    "LOROS",
    "KURI",
    "PAUL HABIB",
    "BORIS",
    "NICO",
    "AZUL",
    "COSMOS F",
    "COSMOS SPEIS",
    "KIKE",
    "DUMA",
    "MACA"
  ] + DUMA_SUBCUSTOMERS
  # TODO: agrega más proveedores aquí
}.freeze

CUSTOMERS_BY_SUPPLIER_EXPANDED = CUSTOMERS_BY_SUPPLIER.merge(
  SUPPLIER_ALIASES.transform_values { |source| CUSTOMERS_BY_SUPPLIER.fetch(source) }
).freeze

CUSTOMER_SUMMARY_GROUPS = {
  "ARQUI" => { match: ->(name) { name.start_with?("ARQUI") }, except: [ "ARQUI KAR" ] },
  "NADJAR" => { match: ->(name) { name.start_with?("NADJAR") } },
  "BEHAR" => { match: ->(name) { name.start_with?("BEHAR") } },
  "DUMA" => { match: ->(name) { name.start_with?("DUMA") } }
}.freeze

ALL_CUSTOMER_NAMES = CUSTOMERS_BY_SUPPLIER_EXPANDED.values.flatten.uniq.freeze
CUSTOMER_SUMMARIES = CUSTOMER_SUMMARY_GROUPS.transform_values do |cfg|
  names = ALL_CUSTOMER_NAMES.select { |name| cfg[:match].call(name) }
  names -= Array(cfg[:except])
  names.sort
end.freeze

DEFAULT_CUSTOMER_FEE_PCT_BY_CUSTOMER = {
  "ADMAS" => 0.025,
  "AJ" => 0.03,
  "ARISTEO" => 0.05,
  "ARQUI" => 0.02,
  "ARQUI ACCRETIO" => 0.02,
  "ARQUI AGROASEMEX" => 0.02,
  "ARQUI ANKA" => 0.02,
  "ARQUI AP" => 0.02,
  "ARQUI ARGENMEX" => 0.02,
  "ARQUI ARGUELLES" => 0.02,
  "ARQUI ASE" => 0.02,
  "ARQUI ATRI" => 0.02,
  "ARQUI AW" => 0.02,
  "ARQUI BAJO" => 0.02,
  "ARQUI BETZA" => 0.02,
  "ARQUI BOTONES" => 0.02,
  "ARQUI CAMPESTRE" => 0.02,
  "ARQUI CARGO" => 0.02,
  "ARQUI CASINO" => 0.02,
  "ARQUI CECY" => 0.02,
  "ARQUI CESAR" => 0.02,
  "ARQUI CESUTEX" => 0.02,
  "ARQUI CLICK" => 0.02,
  "ARQUI CONSUMIBLES" => 0.02,
  "ARQUI COPPER" => 0.02,
  "ARQUI CTN" => 0.02,
  "ARQUI DELUX" => 0.02,
  "ARQUI EDIFICATOP" => 0.02,
  "ARQUI ELIZABETH" => 0.02,
  "ARQUI ELLY" => 0.02,
  "ARQUI END" => 0.02,
  "ARQUI EVELYN" => 0.02,
  "ARQUI EVERARDO" => 0.02,
  "ARQUI EXCELENCIA" => 0.02,
  "ARQUI EXSAN" => 0.02,
  "ARQUI FERVI" => 0.02,
  "ARQUI FIT" => 0.02,
  "ARQUI GABY" => 0.02,
  "ARQUI GORPICK" => 0.02,
  "ARQUI GUADALQUIVIR" => 0.02,
  "ARQUI HELADERO" => 0.02,
  "ARQUI HENTSCHEL" => 0.02,
  "ARQUI HUMANAS" => 0.02,
  "ARQUI IAP" => 0.02,
  "ARQUI IGLESIA" => 0.02,
  "ARQUI IMAAN" => 0.02,
  "ARQUI IMPLEMENTACION" => 0.02,
  "ARQUI INTERBIZ" => 0.02,
  "ARQUI IS SA" => 0.02,
  "ARQUI JAVIER" => 0.02,
  "ARQUI JAZAKA" => 0.02,
  "ARQUI JF" => 0.02,
  "ARQUI JUAREZ" => 0.02,
  "ARQUI JURVAD" => 0.02,
  "ARQUI KAEM" => 0.02,
  "ARQUI KAMPAHAUG" => 0.02,
  "ARQUI KATY" => 0.02,
  "ARQUI KOMUNFE" => 0.02,
  "ARQUI KURI" => 0.02,
  "ARQUI LAURA" => 0.02,
  "ARQUI LESCOR" => 0.02,
  "ARQUI LOCOLUXURY" => 0.02,
  "ARQUI LOYAL" => 0.02,
  "ARQUI LUGA" => 0.02,
  "ARQUI MAGDALENAS" => 0.02,
  "ARQUI MARSAL" => 0.02,
  "ARQUI MC" => 0.02,
  "ARQUI MECA" => 0.02,
  "ARQUI MEZCAL" => 0.02,
  "ARQUI MICHA" => 0.02,
  "ARQUI MICHELLE" => 0.02,
  "ARQUI MIRA" => 0.02,
  "ARQUI MIRA-JURVAD" => 0.02,
  "ARQUI MV" => 0.02,
  "ARQUI NT" => 0.02,
  "ARQUI OLIMANI" => 0.02,
  "ARQUI PAIDI" => 0.02,
  "ARQUI PALMAR" => 0.02,
  "ARQUI PATRICIA" => 0.02,
  "ARQUI PEGALUM" => 0.02,
  "ARQUI PERMAPLAY" => 0.02,
  "ARQUI PINTORES" => 0.02,
  "ARQUI POLANCO" => 0.02,
  "ARQUI PUNTO MAR" => 0.02,
  "ARQUI QUANTON" => 0.02,
  "ARQUI RAGOLI" => 0.02,
  "ARQUI RANCHO" => 0.02,
  "ARQUI RIGHT" => 0.02,
  "ARQUI RUNOXA" => 0.02,
  "ARQUI SADOVICH" => 0.02,
  "ARQUI SALEM" => 0.02,
  "ARQUI SERTRES" => 0.02,
  "ARQUI SIANSHA" => 0.02,
  "ARQUI STONE" => 0.02,
  "ARQUI TCI" => 0.02,
  "ARQUI TECHNIFOAM" => 0.02,
  "ARQUI TECHNO" => 0.02,
  "ARQUI TEURA" => 0.02,
  "ARQUI TMM" => 0.02,
  "ARQUI TO" => 0.02,
  "ARQUI TRX" => 0.02,
  "ARQUI TURQUIE" => 0.02,
  "ARQUI TWM" => 0.02,
  "ARQUI VARIOS" => 0.02,
  "ARQUI VIC" => 0.02,
  "ARQUI VITRAL" => 0.02,
  "ARQUI VS" => 0.02,
  "ARQUI YOMAJO" => 0.02,
  "ARQUI YOROK" => 0.02,
  "ARQUI YTZJAK" => 0.02,
  "ARQUI YVONNE" => 0.02,
  "ARQUI ZORKA" => 0.02,
  "AZUL" => 0.02,
  "BEHAR/PUNTO" => 0.0175,
  "BEHAR/RODIER" => 0.0175,
  "BEHZA" => 0.0175,
  "BENNY SHWARTZ" => 0.045,
  "BERAL" => 0.05,
  "BETO LIS" => 0.025,
  "BORIS" => 0.03,
  "BSID" => 0.03,
  "CHERIZ" => 0.025,
  "CHOCHO" => 0.03,
  "COSMOS F" => 0.02,
  "COSMOS SPEIS" => 0.015,
  "DAN/CARLOS SANDOVAL" => 0.03,
  "DAR" => 0.03,
  **DUMA_GROUP_FEES,
  "FELIPE (SMART)" => 0.01625,
  "FF/INSCOM" => 0.02,
  "FF/LA NET" => 0.02,
  "GGL" => 0.03,
  "IAK" => 0.025,
  "ISMEJU" => 0.025,
  "JABOB/KALI" => 0.025,
  "JABOB/SELIMEX" => 0.025,
  "JAR" => 0.03,
  "KIKE" => 0.025,
  "KURI" => 0.04,
  "LEONIDAS" => 0.02,
  "LEONIDAS/BATERIAS" => 0.02,
  "LEONIDAS/BITSDEV" => 0.02,
  "LEONIDAS/DAREMI" => 0.02,
  "LEONIDAS/ETI" => 0.02,
  "LEONIDAS/GERA" => 0.02,
  "LEONIDAS/ING" => 0.02,
  "LEONIDAS/ITMM" => 0.02,
  "LEONIDAS/MIRAVALLE" => 0.02,
  "LEONIDAS/MONARCA" => 0.02,
  "LEONIDAS/ONLH" => 0.02,
  "LEONIDAS/ROMIX" => 0.02,
  "LEONIDAS/TEAM BITS" => 0.02,
  "LEONIDAS/TOP" => 0.02,
  "LEONIDAS/VEREDIS" => 0.02,
  "LOROS" => 0.03,
  "MACA" => 0.025,
  "MARMAS" => 0.025,
  "MECHY" => 0.03,
  "MS/BJ" => 0.02,
  "MS/MARCOS 27 MICRAS" => 0.02,
  "MS/MARCOS MEX" => 0.02,
  "MS/MARCOS SHEVA" => 0.02,
  "MS/MOY" => 0.0175,
  "MS/MOY CREATIVIDAD" => 0.0175,
  "MS/MOY DICON" => 0.0175,
  "MS/MOY KEIFI" => 0.0175,
  "MS/MOY LATI" => 0.0175,
  "MS/MOY LEV" => 0.0175,
  "MS/MOY LOG" => 0.0175,
  "MS/MOY PISOS" => 0.0175,
  "MS/MOY SAAD SERV" => 0.0175,
  "MS/MOY VARIOS" => 0.0175,
  "MS/SHEVA" => 0.02,
  "NADJAR" => 0.025,
  "NADJAR/RAVER" => 0.02,
  "NADJAR/RUBIO" => 0.02,
  "NICO" => 0.02,
  "PAM" => 0.025,
  "PAUL HABIB" => 0.05,
  "SAMOSH" => 0.03,
  "SELOGIN" => 0.04,
  "SEMAH" => 0.03,
  "YOSH" => 0.02,
  "ZEKE" => 0.03
}.freeze

CUSTOMER_FEE_OVERRIDES = {
  "KJS" => {
    "ADMAS" => 0.025,
    "AJ" => 0.03,
    "ARISTEO" => 0.05,
    "ARQUI" => 0.02,
    "ARQUI ACCRETIO" => 0.02,
    "ARQUI AGROASEMEX" => 0.02,
    "ARQUI ANKA" => 0.02,
    "ARQUI AP" => 0.02,
    "ARQUI ARGENMEX" => 0.02,
    "ARQUI ARGUELLES" => 0.02,
    "ARQUI ASE" => 0.02,
    "ARQUI ATRI" => 0.02,
    "ARQUI AW" => 0.02,
    "ARQUI BAJO" => 0.02,
    "ARQUI BETZA" => 0.02,
    "ARQUI BOTONES" => 0.02,
    "ARQUI CAMPESTRE" => 0.02,
    "ARQUI CARGO" => 0.02,
    "ARQUI CASINO" => 0.02,
    "ARQUI CECY" => 0.02,
    "ARQUI CESAR" => 0.02,
    "ARQUI CESUTEX" => 0.02,
    "ARQUI CLICK" => 0.02,
    "ARQUI CONSUMIBLES" => 0.02,
    "ARQUI COPPER" => 0.02,
    "ARQUI CTN" => 0.02,
    "ARQUI DELUX" => 0.02,
    "ARQUI EDIFICATOP" => 0.02,
    "ARQUI ELIZABETH" => 0.02,
    "ARQUI ELLY" => 0.02,
    "ARQUI END" => 0.02,
    "ARQUI EVELYN" => 0.02,
    "ARQUI EVERARDO" => 0.02,
    "ARQUI EXCELENCIA" => 0.02,
    "ARQUI EXSAN" => 0.02,
    "ARQUI FERVI" => 0.02,
    "ARQUI FIT" => 0.02,
    "ARQUI GABY" => 0.02,
    "ARQUI GORPICK" => 0.02,
    "ARQUI GUADALQUIVIR" => 0.02,
    "ARQUI HELADERO" => 0.02,
    "ARQUI HENTSCHEL" => 0.02,
    "ARQUI HUMANAS" => 0.02,
    "ARQUI IAP" => 0.02,
    "ARQUI IGLESIA" => 0.02,
    "ARQUI IMAAN" => 0.02,
    "ARQUI IMPLEMENTACION" => 0.02,
    "ARQUI INTERBIZ" => 0.02,
    "ARQUI IS SA" => 0.02,
    "ARQUI JAVIER" => 0.02,
    "ARQUI JAZAKA" => 0.02,
    "ARQUI JF" => 0.02,
    "ARQUI JUAREZ" => 0.02,
    "ARQUI JURVAD" => 0.02,
    "ARQUI KAEM" => 0.02,
    "ARQUI KAMPAHAUG" => 0.02,
    "ARQUI KATY" => 0.02,
    "ARQUI KOMUNFE" => 0.02,
    "ARQUI KURI" => 0.02,
    "ARQUI LAURA" => 0.02,
    "ARQUI LESCOR" => 0.02,
    "ARQUI LOCOLUXURY" => 0.02,
    "ARQUI LOYAL" => 0.02,
    "ARQUI LUGA" => 0.02,
    "ARQUI MAGDALENAS" => 0.02,
    "ARQUI MARSAL" => 0.02,
    "ARQUI MC" => 0.02,
    "ARQUI MECA" => 0.02,
    "ARQUI MEZCAL" => 0.02,
    "ARQUI MICHA" => 0.02,
    "ARQUI MICHELLE" => 0.02,
    "ARQUI MIRA" => 0.02,
    "ARQUI MIRA-JURVAD" => 0.02,
    "ARQUI MV" => 0.02,
    "ARQUI NT" => 0.02,
    "ARQUI OLIMANI" => 0.02,
    "ARQUI PAIDI" => 0.02,
    "ARQUI PALMAR" => 0.02,
    "ARQUI PATRICIA" => 0.02,
    "ARQUI PEGALUM" => 0.02,
    "ARQUI PERMAPLAY" => 0.02,
    "ARQUI PINTORES" => 0.02,
    "ARQUI POLANCO" => 0.02,
    "ARQUI PUNTO MAR" => 0.02,
    "ARQUI QUANTON" => 0.02,
    "ARQUI RAGOLI" => 0.02,
    "ARQUI RANCHO" => 0.02,
    "ARQUI RIGHT" => 0.02,
    "ARQUI RUNOXA" => 0.02,
    "ARQUI SADOVICH" => 0.02,
    "ARQUI SALEM" => 0.02,
    "ARQUI SERTRES" => 0.02,
    "ARQUI SIANSHA" => 0.02,
    "ARQUI STONE" => 0.02,
    "ARQUI TCI" => 0.02,
    "ARQUI TECHNIFOAM" => 0.02,
    "ARQUI TECHNO" => 0.02,
    "ARQUI TEURA" => 0.02,
    "ARQUI TMM" => 0.02,
    "ARQUI TO" => 0.02,
    "ARQUI TRX" => 0.02,
    "ARQUI TURQUIE" => 0.02,
    "ARQUI TWM" => 0.02,
    "ARQUI VARIOS" => 0.02,
    "ARQUI VIC" => 0.02,
    "ARQUI VITRAL" => 0.02,
    "ARQUI VS" => 0.02,
    "ARQUI YOMAJO" => 0.02,
    "ARQUI YOROK" => 0.02,
    "ARQUI YTZJAK" => 0.02,
    "ARQUI YVONNE" => 0.02,
    "ARQUI ZORKA" => 0.02,
    "AZUL" => 0.02,
    "BEHAR/PUNTO" => 0.0175,
    "BEHAR/RODIER" => 0.0175,
    "BEHZA" => 0.0175,
    "BENNY SHWARTZ" => 0.045,
    "BERAL" => 0.05,
    "BETO LIS" => 0.025,
    "BORIS" => 0.03,
    "BSID" => 0.03,
    "CHERIZ" => 0.025,
    "CHOCHO" => 0.03,
    "COSMOS F" => 0.02,
    "COSMOS SPEIS" => 0.015,
    "DAN/CARLOS SANDOVAL" => 0.03,
    "DAR" => 0.03,
    **DUMA_GROUP_FEES,
    "FELIPE (SMART)" => 0.01625,
    "FF/INSCOM" => 0.02,
    "FF/LA NET" => 0.02,
    "GGL" => 0.03,
    "IAK" => 0.025,
    "ISMEJU" => 0.025,
    "JABOB/KALI" => 0.025,
    "JABOB/SELIMEX" => 0.025,
    "JAR" => 0.03,
    "KIKE" => 0.025,
    "KURI" => 0.04,
    "LEONIDAS" => 0.02,
    "LEONIDAS/BATERIAS" => 0.02,
    "LEONIDAS/BITSDEV" => 0.02,
    "LEONIDAS/DAREMI" => 0.02,
    "LEONIDAS/ETI" => 0.02,
    "LEONIDAS/GERA" => 0.02,
    "LEONIDAS/ING" => 0.02,
    "LEONIDAS/ITMM" => 0.02,
    "LEONIDAS/MIRAVALLE" => 0.02,
    "LEONIDAS/MONARCA" => 0.02,
    "LEONIDAS/ONLH" => 0.02,
    "LEONIDAS/ROMIX" => 0.02,
    "LEONIDAS/TEAM BITS" => 0.02,
    "LEONIDAS/TOP" => 0.02,
    "LEONIDAS/VEREDIS" => 0.02,
    "LOROS" => 0.03,
    "MACA" => 0.025,
    "MARMAS" => 0.025,
    "MECHY" => 0.03,
    "MS/BJ" => 0.02,
    "MS/MARCOS 27 MICRAS" => 0.02,
    "MS/MARCOS MEX" => 0.02,
    "MS/MARCOS SHEVA" => 0.02,
    "MS/MOY" => 0.0175,
    "MS/MOY CREATIVIDAD" => 0.0175,
    "MS/MOY DICON" => 0.0175,
    "MS/MOY KEIFI" => 0.0175,
    "MS/MOY LATI" => 0.0175,
    "MS/MOY LEV" => 0.0175,
    "MS/MOY LOG" => 0.0175,
    "MS/MOY PISOS" => 0.0175,
    "MS/MOY SAAD SERV" => 0.0175,
    "MS/MOY VARIOS" => 0.0175,
    "MS/SHEVA" => 0.02,
    "NADJAR" => 0.025,
    "NADJAR/RAVER" => 0.02,
    "NADJAR/RUBIO" => 0.02,
    "NICO" => 0.02,
    "PAM" => 0.025,
    "PAUL HABIB" => 0.05,
    "SAMOSH" => 0.03,
    "SELOGIN" => 0.04,
    "SEMAH" => 0.03,
    "YOSH" => 0.02,
    "ZEKE" => 0.03
  },
  "BONANZA" => {
    "ADMAS" => 0.025,
    "AJ" => 0.03,
    "ARISTEO" => 0.05,
    "ARQUI" => 0.02,
    "ARQUI ACCRETIO" => 0.02,
    "ARQUI AGROASEMEX" => 0.02,
    "ARQUI ANKA" => 0.02,
    "ARQUI AP" => 0.02,
    "ARQUI ARGENMEX" => 0.02,
    "ARQUI ARGUELLES" => 0.02,
    "ARQUI ASE" => 0.02,
    "ARQUI ATRI" => 0.02,
    "ARQUI AW" => 0.02,
    "ARQUI BAJO" => 0.02,
    "ARQUI BETZA" => 0.02,
    "ARQUI BOTONES" => 0.02,
    "ARQUI CAMPESTRE" => 0.02,
    "ARQUI CARGO" => 0.02,
    "ARQUI CASINO" => 0.02,
    "ARQUI CECY" => 0.02,
    "ARQUI CESAR" => 0.02,
    "ARQUI CESUTEX" => 0.02,
    "ARQUI CLICK" => 0.02,
    "ARQUI CONSUMIBLES" => 0.02,
    "ARQUI COPPER" => 0.02,
    "ARQUI CTN" => 0.02,
    "ARQUI DELUX" => 0.02,
    "ARQUI EDIFICATOP" => 0.02,
    "ARQUI ELIZABETH" => 0.02,
    "ARQUI ELLY" => 0.02,
    "ARQUI END" => 0.02,
    "ARQUI EVELYN" => 0.02,
    "ARQUI EVERARDO" => 0.02,
    "ARQUI EXCELENCIA" => 0.02,
    "ARQUI EXSAN" => 0.02,
    "ARQUI FERVI" => 0.02,
    "ARQUI FIT" => 0.02,
    "ARQUI GABY" => 0.02,
    "ARQUI GORPICK" => 0.02,
    "ARQUI GUADALQUIVIR" => 0.02,
    "ARQUI HELADERO" => 0.02,
    "ARQUI HENTSCHEL" => 0.02,
    "ARQUI HUMANAS" => 0.02,
    "ARQUI IAP" => 0.02,
    "ARQUI IGLESIA" => 0.02,
    "ARQUI IMAAN" => 0.02,
    "ARQUI IMPLEMENTACION" => 0.02,
    "ARQUI INTERBIZ" => 0.02,
    "ARQUI IS SA" => 0.02,
    "ARQUI JAVIER" => 0.02,
    "ARQUI JAZAKA" => 0.02,
    "ARQUI JF" => 0.02,
    "ARQUI JUAREZ" => 0.02,
    "ARQUI JURVAD" => 0.02,
    "ARQUI KAEM" => 0.02,
    "ARQUI KAMPAHAUG" => 0.02,
    "ARQUI KATY" => 0.02,
    "ARQUI KOMUNFE" => 0.02,
    "ARQUI KURI" => 0.02,
    "ARQUI LAURA" => 0.02,
    "ARQUI LESCOR" => 0.02,
    "ARQUI LOCOLUXURY" => 0.02,
    "ARQUI LOYAL" => 0.02,
    "ARQUI LUGA" => 0.02,
    "ARQUI MAGDALENAS" => 0.02,
    "ARQUI MARSAL" => 0.02,
    "ARQUI MC" => 0.02,
    "ARQUI MECA" => 0.02,
    "ARQUI MEZCAL" => 0.02,
    "ARQUI MICHA" => 0.02,
    "ARQUI MICHELLE" => 0.02,
    "ARQUI MIRA" => 0.02,
    "ARQUI MIRA-JURVAD" => 0.02,
    "ARQUI MV" => 0.02,
    "ARQUI NT" => 0.02,
    "ARQUI OLIMANI" => 0.02,
    "ARQUI PAIDI" => 0.02,
    "ARQUI PALMAR" => 0.02,
    "ARQUI PATRICIA" => 0.02,
    "ARQUI PEGALUM" => 0.02,
    "ARQUI PERMAPLAY" => 0.02,
    "ARQUI PINTORES" => 0.02,
    "ARQUI POLANCO" => 0.02,
    "ARQUI PUNTO MAR" => 0.02,
    "ARQUI QUANTON" => 0.02,
    "ARQUI RAGOLI" => 0.02,
    "ARQUI RANCHO" => 0.02,
    "ARQUI RIGHT" => 0.02,
    "ARQUI RUNOXA" => 0.02,
    "ARQUI SADOVICH" => 0.02,
    "ARQUI SALEM" => 0.02,
    "ARQUI SERTRES" => 0.02,
    "ARQUI SIANSHA" => 0.02,
    "ARQUI STONE" => 0.02,
    "ARQUI TCI" => 0.02,
    "ARQUI TECHNIFOAM" => 0.02,
    "ARQUI TECHNO" => 0.02,
    "ARQUI TEURA" => 0.02,
    "ARQUI TMM" => 0.02,
    "ARQUI TO" => 0.02,
    "ARQUI TRX" => 0.02,
    "ARQUI TURQUIE" => 0.02,
    "ARQUI TWM" => 0.02,
    "ARQUI VARIOS" => 0.02,
    "ARQUI VIC" => 0.02,
    "ARQUI VITRAL" => 0.02,
    "ARQUI VS" => 0.02,
    "ARQUI YOMAJO" => 0.02,
    "ARQUI YOROK" => 0.02,
    "ARQUI YTZJAK" => 0.02,
    "ARQUI YVONNE" => 0.02,
    "ARQUI ZORKA" => 0.02,
    "ARQUI/END" => 0.02,
    "ARQUI/LANDSOFT" => 0.02,
    "AZUL" => 0.02,
    "BEHAR/PUNTO" => 0.0175,
    "BEHAR/RODIER" => 0.0175,
    "BEHZA" => 0.0175,
    "BENNY SHWARTZ" => 0.045,
    "BERAL" => 0.05,
    "BETO LIS" => 0.025,
    "BORIS" => 0.03,
    "BSID" => 0.03,
    "CHERIZ" => 0.025,
    "CHOCHO" => 0.03,
    "COSMOS F" => 0.02,
    "COSMOS SPEIS" => 0.015,
    "DAN/CARLOS SANDOVAL" => 0.03,
    "DAR" => 0.03,
    **DUMA_GROUP_FEES,
    "FELIPE (SMART)" => 0.01625,
    "FF/INSCOM" => 0.02,
    "FF/LA NET" => 0.02,
    "GGL" => 0.03,
    "IAK" => 0.025,
    "ISMEJU" => 0.025,
    "JABOB/KALI" => 0.025,
    "JABOB/SELIMEX" => 0.025,
    "JAR" => 0.03,
    "KIKE" => 0.025,
    "KURI" => 0.04,
    "LEONIDAS" => 0.02,
    "LEONIDAS/BATERIAS" => 0.02,
    "LEONIDAS/BITSDEV" => 0.02,
    "LEONIDAS/DAREMI" => 0.02,
    "LEONIDAS/ETI" => 0.02,
    "LEONIDAS/GERA" => 0.02,
    "LEONIDAS/ING" => 0.02,
    "LEONIDAS/ITMM" => 0.02,
    "LEONIDAS/MIRAVALLE" => 0.02,
    "LEONIDAS/MONARCA" => 0.02,
    "LEONIDAS/ONLH" => 0.02,
    "LEONIDAS/ROMIX" => 0.02,
    "LEONIDAS/TEAM BITS" => 0.02,
    "LEONIDAS/TOP" => 0.02,
    "LEONIDAS/VEREDIS" => 0.02,
    "LOROS" => 0.03,
    "MACA" => 0.025,
    "MARMAS" => 0.025,
    "MECHY" => 0.03,
    "MS/BJ" => 0.02,
    "MS/MARCOS 27 MICRAS" => 0.02,
    "MS/MARCOS MEX" => 0.02,
    "MS/MARCOS SHEVA" => 0.02,
    "MS/MOY" => 0.0175,
    "MS/MOY CREATIVIDAD" => 0.0175,
    "MS/MOY DICON" => 0.0175,
    "MS/MOY KEIFI" => 0.0175,
    "MS/MOY LATI" => 0.0175,
    "MS/MOY LEV" => 0.0175,
    "MS/MOY LOG" => 0.0175,
    "MS/MOY PISOS" => 0.0175,
    "MS/MOY SAAD SERV" => 0.0175,
    "MS/MOY VARIOS" => 0.0175,
    "MS/SHEVA" => 0.02,
    "NADJAR" => 0.025,
    "NADJAR/RAVER" => 0.02,
    "NADJAR/RUBIO" => 0.02,
    "NICO" => 0.02,
    "PAM" => 0.025,
    "PAUL HABIB" => 0.05,
    "SAMOSH" => 0.03,
    "SELOGIN" => 0.04,
    "SEMAH" => 0.03,
    "YOSH" => 0.02,
    "ZEKE" => 0.03
  }
  # TODO: agrega overrides para más proveedores
}.freeze

CUSTOMER_FEE_OVERRIDES_EXPANDED = CUSTOMER_FEE_OVERRIDES.merge(
  SUPPLIER_ALIASES.transform_values { |source| CUSTOMER_FEE_OVERRIDES.fetch(source, {}) }
).freeze

COMMISSION_SPLITS = {
  "KJS" => {
    "ADMAS" => {
      fondo: 0.001,
      jack: 0.0137,
      sam: 0.0003
    },
    "AJ" => {
      fondo: 0.001,
      jack: 0.0187,
      sam: 0.0003
    },
    "ARISTEO" => {
      fondo: 0.001,
      jack: 0.0387,
      sam: 0.0003
    },
    "ARQUI" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI ACCRETIO" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI AGROASEMEX" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI ANKA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI AP" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI ARGENMEX" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI ARGUELLES" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI ASE" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI ATRI" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI AW" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI BAJO" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI BETZA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI BOTONES" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI CAMPESTRE" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI CARGO" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI CASINO" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI CECY" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI CESAR" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI CESUTEX" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI CLICK" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI CONSUMIBLES" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI COPPER" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI CTN" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI DELUX" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI EDIFICATOP" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI ELIZABETH" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI ELLY" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI END" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI EVELYN" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI EVERARDO" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI EXCELENCIA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI EXSAN" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI FERVI" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI FIT" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI GABY" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI GORPICK" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI GUADALQUIVIR" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI HELADERO" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI HENTSCHEL" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI HUMANAS" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI IAP" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI IGLESIA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI IMAAN" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI IMPLEMENTACION" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI INTERBIZ" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI IS SA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI JAVIER" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI JAZAKA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI JF" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI JUAREZ" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI JURVAD" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI KAEM" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI KAMPAHAUG" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI KATY" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI KOMUNFE" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI KURI" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI LAURA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI LESCOR" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI LOCOLUXURY" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI LOYAL" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI LUGA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI MAGDALENAS" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI MARSAL" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI MC" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI MECA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI MEZCAL" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI MICHA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI MICHELLE" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI MIRA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI MIRA-JURVAD" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI MV" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI NT" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI OLIMANI" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI PAIDI" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI PALMAR" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI PATRICIA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI PEGALUM" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI PERMAPLAY" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI PINTORES" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI POLANCO" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI PUNTO MAR" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI QUANTON" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI RAGOLI" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI RANCHO" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI RIGHT" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI RUNOXA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI SADOVICH" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI SALEM" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI SERTRES" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI SIANSHA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI STONE" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI TCI" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI TECHNIFOAM" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI TECHNO" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI TEURA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI TMM" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI TO" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI TRX" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI TURQUIE" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI TWM" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI VARIOS" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI VIC" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI VITRAL" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI VS" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI YOMAJO" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI YOROK" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI YTZJAK" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI YVONNE" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ARQUI ZORKA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "AZUL" => {
      fondo: 0.001,
      jack: 0.0045,
      sam: 0.0045
    },
    "BEHAR/PUNTO" => {
      fondo: 0.001,
      jack: 0.0052,
      sam: 0.0003
    },
    "BEHAR/RODIER" => {
      fondo: 0.001,
      jack: 0.0052,
      sam: 0.0003
    },
    "BEHZA" => {
      fondo: 0.001,
      jack: 0.0052,
      sam: 0.0003
    },
    "BENNY SHWARTZ" => {
      fondo: 0.001,
      jack: 0.0162,
      sam: 0.0003
    },
    "BERAL" => {
      fondo: 0.001,
      jack: 0.0187,
      sam: 0.0003
    },
    "BETO LIS" => {
      fondo: 0.001,
      jack: 0.0137,
      sam: 0.0003
    },
    "BORIS" => {
      fondo: 0.001,
      jack: 0.0137,
      sam: 0.0003
    },
    "BSID" => {
      fondo: 0.001,
      jack: 0.0187,
      sam: 0.0003
    },
    "CHERIZ" => {
      fondo: 0.001,
      jack: 0.0137,
      sam: 0.0003
    },
    "CHOCHO" => {
      fondo: 0.001,
      jack: 0.0187,
      sam: 0.0003
    },
    "COSMOS F" => {
      fondo: 0.001,
      jack: 0.0045,
      sam: 0.0045
    },
    "COSMOS SPEIS" => {
      fondo: 0.001,
      jack: 0.002,
      sam: 0.002
    },
    "DAN/CARLOS SANDOVAL" => {
      fondo: 0.001,
      jack: 0.0137,
      sam: 0.0003
    },
    "DAR" => {
      fondo: 0.001,
      jack: 0.0137,
      sam: 0.0003
    },
    **DUMA_SPLITS_BY_SUPPLIER["KJS"],
    "FELIPE (SMART)" => {
      fondo: 0.001,
      jack: 0.00495,
      sam: 0.0003
    },
    "FF/INSCOM" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "FF/LA NET" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "GGL" => {
      fondo: 0.001,
      jack: 0.0187,
      sam: 0.0003
    },
    "IAK" => {
      fondo: 0.001,
      jack: 0.0137,
      sam: 0.0003
    },
    "ISMEJU" => {
      fondo: 0.001,
      jack: 0.0137,
      sam: 0.0003
    },
    "JABOB/KALI" => {
      fondo: 0.001,
      jack: 0.0137,
      sam: 0.0003
    },
    "JABOB/SELIMEX" => {
      fondo: 0.001,
      jack: 0.0137,
      sam: 0.0003
    },
    "JAR" => {
      fondo: 0.001,
      jack: 0.0187,
      sam: 0.0003
    },
    "KIKE" => {
      fondo: 0.001,
      jack: 0.007,
      sam: 0.007
    },
    "KURI" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS/BATERIAS" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS/BITSDEV" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS/DAREMI" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS/ETI" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS/GERA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS/ING" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS/ITMM" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS/MIRAVALLE" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS/MONARCA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS/ONLH" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS/ROMIX" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS/TEAM BITS" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS/TOP" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LEONIDAS/VEREDIS" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "LOROS" => {
      fondo: 0.001,
      jack: 0.0187,
      sam: 0.0003
    },
    "MACA" => {
      fondo: 0.001,
      jack: 0.007,
      sam: 0.007
    },
    "MARMAS" => {
      fondo: 0.001,
      jack: 0.0137,
      sam: 0.0003
    },
    "MECHY" => {
      fondo: 0.001,
      jack: 0.0187,
      sam: 0.0003
    },
    "MS/BJ" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "MS/MARCOS 27 MICRAS" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "MS/MARCOS MEX" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "MS/MARCOS SHEVA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "MS/MOY" => {
      fondo: 0.001,
      jack: 0.0062,
      sam: 0.0003
    },
    "MS/MOY CREATIVIDAD" => {
      fondo: 0.001,
      jack: 0.0062,
      sam: 0.0003
    },
    "MS/MOY DICON" => {
      fondo: 0.001,
      jack: 0.0062,
      sam: 0.0003
    },
    "MS/MOY KEIFI" => {
      fondo: 0.001,
      jack: 0.0062,
      sam: 0.0003
    },
    "MS/MOY LATI" => {
      fondo: 0.001,
      jack: 0.0062,
      sam: 0.0003
    },
    "MS/MOY LEV" => {
      fondo: 0.001,
      jack: 0.0062,
      sam: 0.0003
    },
    "MS/MOY LOG" => {
      fondo: 0.001,
      jack: 0.0062,
      sam: 0.0003
    },
    "MS/MOY PISOS" => {
      fondo: 0.001,
      jack: 0.0062,
      sam: 0.0003
    },
    "MS/MOY SAAD SERV" => {
      fondo: 0.001,
      jack: 0.0062,
      sam: 0.0003
    },
    "MS/MOY VARIOS" => {
      fondo: 0.001,
      jack: 0.0062,
      sam: 0.0003
    },
    "MS/SHEVA" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "NADJAR" => {
      fondo: 0.001,
      jack: 0.0137,
      sam: 0.0003
    },
    "NADJAR/RAVER" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "NADJAR/RUBIO" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "NICO" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "PAM" => {
      fondo: 0.001,
      jack: 0.0137,
      sam: 0.0003
    },
    "PAUL HABIB" => {
      fondo: 0.001,
      jack: 0.0387,
      sam: 0.0003
    },
    "SAMOSH" => {
      fondo: 0.001,
      jack: 0.0187,
      sam: 0.0003
    },
    "SELOGIN" => {
      fondo: 0.001,
      jack: 0.0287,
      sam: 0.0003
    },
    "SEMAH" => {
      fondo: 0.001,
      jack: 0.0187,
      sam: 0.0003
    },
    "YOSH" => {
      fondo: 0.001,
      jack: 0.0087,
      sam: 0.0003
    },
    "ZEKE" => {
      fondo: 0.001,
      jack: 0.0187,
      sam: 0.0003
    },
    "__default__" => {
      fondo: 0.003,
      jack: 0.0087,
      sam: 0.0003
    }
  },
  "BONANZA" => {
    "ADMAS" => {
      fondo: 0.001,
      jack: 0.0117,
      sam: 0.0003
    },
    "AJ" => {
      fondo: 0.001,
      jack: 0.0167,
      sam: 0.0003
    },
    "ARISTEO" => {
      fondo: 0.001,
      jack: 0.0367,
      sam: 0.0003
    },
    "ARQUI" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI ACCRETIO" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI AGROASEMEX" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI ANKA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI AP" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI ARGENMEX" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI ARGUELLES" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI ASE" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI ATRI" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI AW" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI BAJO" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI BETZA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI BOTONES" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI CAMPESTRE" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI CARGO" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI CASINO" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI CECY" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI CESAR" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI CESUTEX" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI CLICK" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI CONSUMIBLES" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI COPPER" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI CTN" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI DELUX" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI EDIFICATOP" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI ELIZABETH" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI ELLY" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI END" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI EVELYN" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI EVERARDO" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI EXCELENCIA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI EXSAN" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI FERVI" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI FIT" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI GABY" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI GORPICK" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI GUADALQUIVIR" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI HELADERO" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI HENTSCHEL" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI HUMANAS" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI IAP" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI IGLESIA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI IMAAN" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI IMPLEMENTACION" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI INTERBIZ" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI IS SA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI JAVIER" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI JAZAKA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI JF" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI JUAREZ" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI JURVAD" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI KAEM" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI KAMPAHAUG" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI KATY" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI KOMUNFE" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI KURI" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI LAURA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI LESCOR" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI LOCOLUXURY" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI LOYAL" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI LUGA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI MAGDALENAS" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI MARSAL" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI MC" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI MECA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI MEZCAL" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI MICHA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI MICHELLE" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI MIRA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI MIRA-JURVAD" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI MV" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI NT" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI OLIMANI" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI PAIDI" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI PALMAR" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI PATRICIA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI PEGALUM" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI PERMAPLAY" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI PINTORES" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI POLANCO" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI PUNTO MAR" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI QUANTON" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI RAGOLI" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI RANCHO" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI RIGHT" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI RUNOXA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI SADOVICH" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI SALEM" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI SERTRES" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI SIANSHA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI STONE" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI TCI" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI TECHNIFOAM" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI TECHNO" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI TEURA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI TMM" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI TO" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI TRX" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI TURQUIE" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI TWM" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI VARIOS" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI VIC" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI VITRAL" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI VS" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI YOMAJO" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI YOROK" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI YTZJAK" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI YVONNE" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI ZORKA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI/END" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ARQUI/LANDSOFT" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "AZUL" => {
      fondo: 0.001,
      jack: 0.0035,
      sam: 0.0035
    },
    "BEHAR/PUNTO" => {
      fondo: 0.0005,
      jack: 0.0042,
      sam: 0.0003
    },
    "BEHAR/RODIER" => {
      fondo: 0.0005,
      jack: 0.0042,
      sam: 0.0003
    },
    "BEHZA" => {
      fondo: 0.0005,
      jack: 0.0042,
      sam: 0.0003
    },
    "BENNY SHWARTZ" => {
      fondo: 0.001,
      jack: 0.0217,
      sam: 0.0003
    },
    "BERAL" => {
      fondo: 0.001,
      jack: 0.0167,
      sam: 0.0003
    },
    "BETO LIS" => {
      fondo: 0.001,
      jack: 0.0117,
      sam: 0.0003
    },
    "BORIS" => {
      fondo: 0.001,
      jack: 0.0117,
      sam: 0.0003
    },
    "BSID" => {
      fondo: 0.001,
      jack: 0.0167,
      sam: 0.0003
    },
    "CHERIZ" => {
      fondo: 0.001,
      jack: 0.0117,
      sam: 0.0003
    },
    "CHOCHO" => {
      fondo: 0.001,
      jack: 0.0167,
      sam: 0.0003
    },
    "COSMOS F" => {
      fondo: 0.001,
      jack: 0.0035,
      sam: 0.0035
    },
    "COSMOS SPEIS" => {
      fondo: 0.001,
      jack: 0.001,
      sam: 0.001
    },
    "DAN/CARLOS SANDOVAL" => {
      fondo: 0.001,
      jack: 0.0117,
      sam: 0.0003
    },
    "DAR" => {
      fondo: 0.001,
      jack: 0.0117,
      sam: 0.0003
    },
    **DUMA_SPLITS_BY_SUPPLIER["BONANZA"],
    "FELIPE (SMART)" => {
      fondo: 0.001,
      jack: 0.00295,
      sam: 0.0003
    },
    "FF/INSCOM" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "FF/LA NET" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "GGL" => {
      fondo: 0.001,
      jack: 0.0167,
      sam: 0.0003
    },
    "IAK" => {
      fondo: 0.001,
      jack: 0.0117,
      sam: 0.0003
    },
    "ISMEJU" => {
      fondo: 0.001,
      jack: 0.0117,
      sam: 0.0003
    },
    "JABOB/KALI" => {
      fondo: 0.001,
      jack: 0.0117,
      sam: 0.0003
    },
    "JABOB/SELIMEX" => {
      fondo: 0.001,
      jack: 0.0117,
      sam: 0.0003
    },
    "JAR" => {
      fondo: 0.001,
      jack: 0.0167,
      sam: 0.0003
    },
    "KIKE" => {
      fondo: 0.001,
      jack: 0.006,
      sam: 0.006
    },
    "KURI" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS/BATERIAS" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS/BITSDEV" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS/DAREMI" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS/ETI" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS/GERA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS/ING" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS/ITMM" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS/MIRAVALLE" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS/MONARCA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS/ONLH" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS/ROMIX" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS/TEAM BITS" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS/TOP" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LEONIDAS/VEREDIS" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "LOROS" => {
      fondo: 0.001,
      jack: 0.0167,
      sam: 0.0003
    },
    "MACA" => {
      fondo: 0.001,
      jack: 0.006,
      sam: 0.006
    },
    "MARMAS" => {
      fondo: 0.001,
      jack: 0.0117,
      sam: 0.0003
    },
    "MECHY" => {
      fondo: 0.001,
      jack: 0.0167,
      sam: 0.0003
    },
    "MS/BJ" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "MS/MARCOS 27 MICRAS" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "MS/MARCOS MEX" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "MS/MARCOS SHEVA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "MS/MOY" => {
      fondo: 0.001,
      jack: 0.0042,
      sam: 0.0003
    },
    "MS/MOY CREATIVIDAD" => {
      fondo: 0.001,
      jack: 0.0042,
      sam: 0.0003
    },
    "MS/MOY DICON" => {
      fondo: 0.001,
      jack: 0.0042,
      sam: 0.0003
    },
    "MS/MOY KEIFI" => {
      fondo: 0.001,
      jack: 0.0042,
      sam: 0.0003
    },
    "MS/MOY LATI" => {
      fondo: 0.001,
      jack: 0.0042,
      sam: 0.0003
    },
    "MS/MOY LEV" => {
      fondo: 0.001,
      jack: 0.0042,
      sam: 0.0003
    },
    "MS/MOY LOG" => {
      fondo: 0.001,
      jack: 0.0042,
      sam: 0.0003
    },
    "MS/MOY PISOS" => {
      fondo: 0.001,
      jack: 0.0042,
      sam: 0.0003
    },
    "MS/MOY SAAD SERV" => {
      fondo: 0.001,
      jack: 0.0042,
      sam: 0.0003
    },
    "MS/MOY VARIOS" => {
      fondo: 0.001,
      jack: 0.0042,
      sam: 0.0003
    },
    "MS/SHEVA" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "NADJAR" => {
      fondo: 0.001,
      jack: 0.0117,
      sam: 0.0003
    },
    "NADJAR/RAVER" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "NADJAR/RUBIO" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "NICO" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "PAM" => {
      fondo: 0.001,
      jack: 0.0117,
      sam: 0.0003
    },
    "PAUL HABIB" => {
      fondo: 0.001,
      jack: 0.0367,
      sam: 0.0003
    },
    "SAMOSH" => {
      fondo: 0.001,
      jack: 0.0167,
      sam: 0.0003
    },
    "SELOGIN" => {
      fondo: 0.001,
      jack: 0.0267,
      sam: 0.0003
    },
    "SEMAH" => {
      fondo: 0.001,
      jack: 0.0167,
      sam: 0.0003
    },
    "YOSH" => {
      fondo: 0.001,
      jack: 0.0067,
      sam: 0.0003
    },
    "ZEKE" => {
      fondo: 0.001,
      jack: 0.0167,
      sam: 0.0003
    },
    "__default__" => {
      fondo: 0.004,
      jack: 0.0067,
      sam: 0.0003
    }
  }
  # TODO: agrega splits para más proveedores
}.freeze

COMMISSION_SPLITS_EXPANDED = COMMISSION_SPLITS.merge(
  SUPPLIER_ALIASES.transform_values { |source| COMMISSION_SPLITS.fetch(source) }
).freeze

def slug_code(str)
  str.to_s.parameterize(separator: "_").upcase
end

def pct_label(value)
  return "default" if value.nil?
  format("%.4f", value)
end

def save_with_status!(record)
  record.save!
  return :created if record.previous_changes.key?("id")
  tracked_changes = record.previous_changes.keys - %w[id created_at updated_at]
  tracked_changes.any? ? :updated : :unchanged
end

def ensure_user!(email:, name:, code:, **_opts)
  user = User.find_or_initialize_by(email: email)
  user.name = name
  user.code = code
  user.password ||= SecureRandom.hex(16)
  status = save_with_status!(user)
  [ user, status ]
end

def ensure_supplier!(code:, name:, default_analysis_pct:)
  supplier = Supplier.find_or_initialize_by(code: code)
  supplier.name = name
  supplier.default_analysis_pct = default_analysis_pct
  status = save_with_status!(supplier)
  [ supplier, status ]
end

def ensure_customer!(name, default_customer_fee_pct:)
  code = slug_code(name)
  customer = Customer.find_or_initialize_by(code: code)
  customer.name = name
  customer.default_customer_fee_pct = default_customer_fee_pct
  status = save_with_status!(customer)
  [ customer, status ]
end

def link_customer_supplier!(customer, supplier, fee_pct:)
  link = CustomerSupplier.find_or_initialize_by(customer: customer, supplier: supplier)
  link.customer_fee_pct = fee_pct
  status = save_with_status!(link)
  [ link, status ]
end

def upsert_commission_default!(supplier:, customer:, user:, pct:)
  raise ArgumentError, "pct fuera de rango" unless pct && pct >= 0 && pct < 1
  record = CommissionDefault.find_or_initialize_by(
    supplier: supplier,
    customer: customer,
    user: user
  )
  record.commission_pct = pct
  status = save_with_status!(record)
  [ record, status ]
end

ActiveRecord::Base.transaction do
  counters = Hash.new(0)

  puts "== Resumen de clientes agrupados =="
  CUSTOMER_SUMMARIES.each do |summary_name, members|
    puts "#{summary_name}: #{members.join(', ')}"
  end

  puts "== Usuarios base =="
  user_records = {}
  USERS.each do |attrs|
    user, status = ensure_user!(**attrs)
    user_records[attrs[:key]] = user
    counters["users_#{status}".to_sym] += 1
    puts "#{attrs[:email]} => #{status}"
  end

  puts "== Proveedores =="
  supplier_records = {}
  SUPPLIERS.each do |attrs|
    supplier, status = ensure_supplier!(**attrs)
    supplier_records[attrs[:code]] = supplier
    counters["suppliers_#{status}".to_sym] += 1
    puts "#{attrs[:code]} => #{status}"
  end

  puts "== Clientes, duplas y splits =="
  CUSTOMERS_BY_SUPPLIER_EXPANDED.each do |supplier_code, customer_names|
    supplier = supplier_records[supplier_code] || Supplier.find_by!(code: supplier_code)
    customer_names.each do |customer_name|
      default_fee = DEFAULT_CUSTOMER_FEE_PCT_BY_CUSTOMER[customer_name]
      customer, customer_status = ensure_customer!(customer_name, default_customer_fee_pct: default_fee)
      counters["customers_#{customer_status}".to_sym] += 1

      fee_override = CUSTOMER_FEE_OVERRIDES_EXPANDED.dig(supplier_code, customer_name)
      link, link_status = link_customer_supplier!(customer, supplier, fee_pct: fee_override)
      counters["customer_suppliers_#{link_status}".to_sym] += 1

      split_catalog = COMMISSION_SPLITS_EXPANDED.fetch(supplier_code) { {} }
      default_split = split_catalog["__default__"] || {}
      custom_split = split_catalog[customer_name] || {}
      split = {
        jack: custom_split[:jack] || default_split[:jack],
        sam: custom_split[:sam] || default_split[:sam],
        fondo: custom_split[:fondo] || default_split[:fondo]
      }

      unless split.values.all? { |value| value && value >= 0 && value < 1 }
        raise ArgumentError, "Falta split para #{supplier_code} / #{customer_name}"
      end

      split.each do |role, pct|
        user = user_records.fetch(role)
        _, cd_status = upsert_commission_default!(
          supplier: supplier,
          customer: customer,
          user: user,
          pct: pct
        )
        counters["commission_defaults_#{cd_status}".to_sym] += 1
      end

      Sales::Subagents.entries_for(supplier_code, customer_name).each do |subagent|
        pct = subagent[:pct]
        unless pct && pct >= 0 && pct < 1
          raise ArgumentError, "Pct inválido para subagente #{supplier_code} / #{customer_name}"
        end

        _, cd_status = upsert_commission_default!(
          supplier: supplier,
          customer: customer,
          user: user_records.fetch(:subagent),
          pct: pct
        )
        counters["commission_defaults_#{cd_status}".to_sym] += 1
      end

      puts format(
        "%s / %s => fee_dupla=%s splits: JACK=%s SAM=%s FONDO=%s",
        supplier_code,
        customer_name,
        pct_label(fee_override),
        pct_label(split[:jack]),
        pct_label(split[:sam]),
        pct_label(split[:fondo])
      )
    end
  end

  puts "== Totales =="
  counters.sort.each do |key, value|
    puts format("%-28s %5d", key, value)
  end
end
