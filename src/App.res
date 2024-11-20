%%raw("import './App.css'")
open WebAPI

// See https://forum.rescript-lang.org/t/how-to-get-input-value-in-rescript/1037/5?u=nojaf
let getEventValue = e => {
  let target = e->JsxEvent.Form.target
  let input: DOMAPI.htmlInputElement = Prelude.unsafeConversation(target)
  input.value
}

@module("usehooks-ts")
external useDebounceCallback: ('v => unit, int) => 'v => unit = "useDebounceCallback"

type state =
  | Loading(string)
  | Failed({id: string, reason: string})
  | Data({id: string, name: string, image: string})

let getId = state => {
  switch state {
  | Loading(id)
  | Failed({id})
  | Data({id}) => id
  }
}

type pkmn = {
  name: string,
  image: string,
}

let pkmnSchema = S.object(s => {
  {
    name: s.field("name", S.string),
    image: s.nestedField("sprites", "front_default", S.string),
  }
})

let decodeJson = (json: Js.Json.t) => {
  switch S.parseWith(json, pkmnSchema) {
  | Ok(pkmn) => Ok(pkmn)
  | Error(e) => Error(e->S.Error.message)
  }
}

let unknownErrorMessage = "Unexpected error during API request"

@react.component
let make = () => {
  let (state, setState) = React.useState(() => Loading("25"))
  // Add some debouncing to typed input
  let load = useDebounceCallback(text => setState(_ => Loading(text)), 500)

  React.useEffect1(() => {
    Int.fromString(getId(state))->Option.forEach(id => {
      let idAsString = Int.toString(id)
      fetch(`https://pokeapi.co/api/v2/pokemon/${idAsString}`)
      ->Promise.then(
        response => {
          let code = response.status
          if code == 200 {
            response->Response.json->Promise.thenResolve(decodeJson)
          } else {
            Promise.resolve(Error(`The API could not return a pokemon for "${idAsString}"`))
          }
        },
      )
      ->Promise.catch(
        exn => {
          let reason = switch exn {
          | Exn.Error(exn) => Exn.message(exn)->Option.getOr(unknownErrorMessage)
          | _ => unknownErrorMessage
          }
          Promise.resolve(Error(reason))
        },
      )
      ->Promise.thenResolve(
        result => {
          switch result {
          | Ok({name, image}) =>
            setState(
              _ => Data({
                id: idAsString,
                name,
                image,
              }),
            )
          | Error(err) =>
            setState(
              _ => Failed({
                id: idAsString,
                reason: err,
              }),
            )
          }
        },
      )
      ->Promise.done
    })

    None
  }, [getId(state)])

  let (msg, className, img) = switch state {
  | Loading(id) => (`Loading ${id}...`, "loading", React.null)
  | Data({name, image}) => (name, "", <img src=image />)
  | Failed({reason}) => (reason, "error", React.null)
  }

  <>
    <div>
      <a href="https://rescript-lang.org/">
        <img src="https://avatars.githubusercontent.com/u/29257325?s=200&v=4" />
      </a>
    </div>
    <h1> {React.string("Hello ReScript")} </h1>
    <div className="card">
      <input
        type_="number"
        placeholder="Enter the number of a Pokemon"
        defaultValue={getId(state)}
        onChange={ev => ev->getEventValue->load}
      />
      <p className> {React.string(msg)} </p>
      img
    </div>
  </>
}
