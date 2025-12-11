# Ensure numeric helpers include thousands delimiters across the app.
I18n.backend.store_translations(:en, {
  number: {
    format: { delimiter: ",", separator: ".", precision: 2 },
    currency: { format: { delimiter: ",", separator: ".", format: "%u%n", precision: 2 } }
  }
})

I18n.backend.store_translations(:es, {
  number: {
    format: { delimiter: ",", separator: ".", precision: 2 },
    currency: { format: { delimiter: ",", separator: ".", format: "%u%n", precision: 2 } }
  }
})
