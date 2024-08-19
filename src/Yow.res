type yow = {
  x: int,
  y: string,
}

exception NotAnInt

let stringSchemaToInt = schema =>
  schema->S.transform(s => {
    parser: string => {
      switch string->Int.fromString {
      | None => s.fail("Invalid Int value")
      | Some(int) => int
      }
    },
  })

let yowSchema = S.object(s => {
  {
    x: s.field("x", S.string->stringSchemaToInt),
    y: s.field("y", S.string),
  }
})

let formData = %raw(`{ "x": "a1a", "y": "yow" }`)

module FormData = {
  type t

  @new
  external make: 'form => t = "FormData"

  @send
  external entries: t => Iterator.t<_> = "entries"
}

module Object = {
  @val @scope("Object")
  external fromEntries: Iterator.t<_> => Js.Dict.t<string> = "fromEntries"
}

@react.component
let make = () => {
  let onSubmit = ev => {
    ev->ReactEvent.Form.preventDefault
    let target = ev->ReactEvent.Form.target
    let formData = FormData.make(target)
    let json = formData->FormData.entries->Object.fromEntries
    S.parseAnyWith(json, yowSchema)->Console.log
  }

  <form onSubmit>
    <input type_="number" placeholder="x" name="x" value={"2"} />
    <input type_="text" placeholder="y" name="y" value={"k"} />
    <button type_="submit"> {React.string(`Submit`)} </button>
  </form>
}
