/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.*/

// glossarium figure kind
#let __glossarium_figure = "glossarium_entry"
// prefix of label for references query
#let __glossary_label_prefix = "glossary:"
// global state containing the glossary entry and their location
#let __glossary_entries = state("__glossary_entries", (:))

#let __glossarium_error_prefix = "glossarium error : "

#let __query_labels_with_key(loc, key, before: false) = {
  if before {
    query(
      selector(label(__glossary_label_prefix + key)).before(loc, inclusive: false),
      loc,
    )
  } else {
    query(selector(label(__glossary_label_prefix + key)), loc)
  }
}

#let __normalize-entry-list(entry_list) = {
  let new-list = ()
  for entry in entry_list {
    new-list.push((
      key: entry.key,
      short: entry.short,
      plural: entry.at("plural", default: ""),
      long: entry.at("long", default: ""),
      longplural: entry.at("longplural", default: ""),
      desc: entry.at("desc", default: ""),
      group: entry.at("group", default: ""),
    ))
  }
  return new-list
}

#let print-glossary(
  entry_list,
  show-all: false,
  disable-back-references: false,
  enable-group-pagebreak: false,
) = {
  let entries = __normalize-entry-list(entry_list)
  __glossary_entries.update(x => {
    for entry in entry_list {
      x.insert(entry.key, entry)
    }
     
    x
  })
   
  let groups = entries.map(x => x.at("group", default: "")).dedup()
  // move no group to the front
  groups.insert(0, "")
  groups.pop()
   
  for group in groups.sorted() {
    if group != "" [#heading(group, level: 2) ]
    for entry in entries.sorted(key: x => x.key) {
      if entry.group == group {
        [
          #show figure.where(kind: __glossarium_figure): it => it.caption
          #par(
            hanging-indent: 1em,
            first-line-indent: 0em,
          )[
            #figure(
              supplement: "",
              kind: __glossarium_figure,
              numbering: none,
              caption: {
                context {
                  let term_references = __query_labels_with_key(here(), entry.key)
                  if term_references.len() != 0 or show-all {
                    let desc = entry.at("desc", default: "")
                    let long = entry.at("long", default: "")
                    let hasLong = long != "" and long != []
                    let hasDesc = desc != "" and desc != []
             
                    grid(
                      columns: (auto, 1fr, auto),
                      [
                        #set text(weight: 600)
                        #if hasLong {
                          emph(entry.short) + [ -- ] + entry.long
                        } else {
                          emph(entry.short)
                        }
                      ],
                      repeat("  .  "),
                      [
                        #if disable-back-references != true {
                          h(3pt)
                          term_references.map(x => x.location()).sorted(key: x => x.page()).fold(
                            (values: (), pages: ()),
                            ((values, pages), x) => if pages.contains(x.page()) {
                              (values: values, pages: pages)
                            } else {
                              values.push(x)
                              pages.push(x.page())
                              (values: values, pages: pages)
                            },
                          ).values.map(x => {
                             let page-numbering = x.page-numbering();
                              if page-numbering == none {
                                page-numbering = "1"
                              }
                              link(x)[#numbering(page-numbering, ..counter(page).at(x))]
                            }
                          ).join(", ")
                        }
                      ],
                    )
                  }
                }
              },
            )[] #label(entry.key)
          ]
          #parbreak()
        ]
      }
    }
    if enable-group-pagebreak { pagebreak(weak: true) }
  }
};