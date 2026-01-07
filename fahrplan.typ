#let event_data = yaml(sys.inputs.at("datafile", default: "data.yaml"))
#let f_version = sys.inputs.at("version", default: "")
#let s_version = if f_version != "" {
  text(size: 10pt)[#h(5mm)\(#raw(str(f_version)))]
}
#let bg_color = if sys.inputs.at("yellow", default: "false") == "true" {
  yellow
} else {
  white
}

#let scale_facor = event_data.at("page").at("scale_factor", default: 1.0)

#set document(
  title: [Fahrplan -- ] + event_data.at("header").at("title"),
)

#set page(
  paper: event_data.at("page").at("paper"),
  margin: 10mm,
  fill: bg_color,
)

#set text(
  font: "Noto Sans",
  10pt * scale_facor,
)

#set text(lang: "de")

#let header(data) = {
  let logo = if (data.at("logo", default: "") != "") {
    place(right)[
      #image(data.at("logo"), height: 1.7cm)
    ]
  }
  text(size: 16pt * scale_facor)[
    #logo
    Gültig ab: #data.at("date", default: datetime.today().display())#s_version

    *Abfahrt* _Departure_ _Départ_ #h(1cm * data.at("title_space")) *#data.at("title")*
  ]
}

#let footer(data) = {
  v(5mm * scale_facor)
  [*Veranstaltungen im Hauptverkehr*\/_Main events_/_Événements principaux_]
  let category_data = ()
  for (cat) in data.categories {
    let cat_id = cat.at("display")
    let cat_name_de = cat.at("name_de")
    let cat_name_en = cat.at("name_en")

    category_data.push([*#cat_id*])
    category_data.push([#cat_name_de/#emph[#cat_name_en]])
  }
  grid(
    columns: 2,
    gutter: 5pt,
    ..category_data,
  )
  v(2mm)

  let location_data = ()
  for (location) in data.locations {
    let location_id = location.at("display")
    let location_name = location.at("name")

    location_data.push([*#location_id*])
    location_data.push([#location_name])
  }
  grid(
    columns: 2,
    column-gutter: 5pt,
    row-gutter: 10pt,
    ..location_data,
  )

  text[
    Angaben ohne Gewähr. Änderungen und Irrtümer vorbehalten. Bitte die örtlichen Kalenderdurchsagen beachten. #v(2mm)
  ]
  if (data.calendar_urls.len() > 1) {
    for (link_url) in data.calendar_urls {
      [- #link(link_url)]
    }
  } else if (data.calendar_urls.len() == 1) {
    link(data.calendar_urls.at(0))
  }

  v(5mm * scale_facor)
  text[
    #link("https://github.com/ccoors/typst-fahrplan")
  ]
}

#header(event_data.header)

#let timetable(data) = {
  let table_data = ()
  let seen_trains = ()
  let available_categories = ()
  let available_locations = ()
  for (cat) in data.footer.categories {
    let cd = cat.at("display")
    if (available_categories.contains(cd)) {
      panic("Category " + cd + " is not unique")
    }
    available_categories.push(cd)
  }
  for (loc) in data.footer.locations {
    let ld = loc.at("display")
    if (available_locations.contains(ld)) {
      panic("Location " + ld + " is not unique")
    }
    available_locations.push(ld)
  }

  for (cat) in data.data {
    let cat_name = cat.at("name")
    table_data.push(table.cell(fill: black, colspan: 2)[])
    table_data.push(table.cell(fill: black)[#text(
      fill: bg_color,
      [*#cat_name*],
    )])
    table_data.push(table.cell(fill: black)[])

    let events = cat.at("events")
    for (no, event) in events.enumerate() {
      if (no > 0) {
        table_data.push(table.hline())
      }
      let date_hint = event.at("date_hint", default: "")
      if (date_hint.len() > 0) {
        date_hint = text(
          size: 7pt * scale_facor,
          black,
          weight: "bold",
        )[#date_hint \ ]
      }
      let txt = [#strong[#event.at("title")] \ #text(size: 8pt * scale_facor)[#event.at("description")] \ #date_hint\(→ #event.at("end"))]

      table_data.push(text(weight: "bold")[#event.at("time")])
      let train_cat = event.at("train_id")
      let train_no = event.at("train_no")
      let train_platform = event.at("platform")
      if (not available_categories.contains(train_cat)) {
        panic("Unknown category " + train_cat)
      }
      if (type(train_platform) == array) {
        for tp in train_platform {
          if (not available_locations.contains(tp)) {
            panic("Unknown platform " + tp)
          }
        }
        train_platform = train_platform.join(", ")
      } else {
        if (not available_locations.contains(train_platform)) {
          panic("Unknown platform " + train_platform)
        }
      }
      table_data.push([#strong[#train_cat]\u{00A0}#train_no])
      let train_id = train_cat + train_no
      if (seen_trains.contains(train_id)) {
        panic("Train " + train_id + " is not unique")
      }
      seen_trains.push(train_id)
      table_data.push([#txt])
      table_data.push([#train_platform])
    }
  }

  table_data.push(table.cell(fill: none, colspan: 4)[#footer(data.footer)])

  columns(event_data.at("page").at("columns"), gutter: 6pt)[
    #table(
      columns: (auto, auto, auto, 1.5cm * scale_facor),
      inset: 4pt,
      align: (left, left, left, right),
      fill: (x, y) => if y == 0 {
        gray.transparentize(30%)
      } else if x == 0 {
        gray.transparentize(60%)
      },
      stroke: none,
      table.header(
        [*Zeit* \ _Time_],
        [*Zug* \ _Train_],
        [*Richtung* \ _Destination_],
        [*Gleis* \ _Platform_],
        table.hline(),
      ),
      ..table_data,
    )
  ]
}

#timetable(event_data)
