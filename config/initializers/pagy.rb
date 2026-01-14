require "pagy/extras/i18n"
require "pagy/extras/array"

Pagy::I18n.load(locale: "es")

Pagy::DEFAULT[:items]      = 25
Pagy::DEFAULT[:size]       = [ 1, 4, 4, 1 ]
Pagy::DEFAULT[:aria_label] = "Paginación"
Pagy::DEFAULT[:i18n]       = { locale: "es" }
