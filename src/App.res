%%raw("import './App.css'")

// See https://forum.rescript-lang.org/t/how-to-get-input-value-in-rescript/1037/5?u=nojaf
let getEventValue = e => {
  let target = e->JsxEvent.Form.target
  (target["value"]: string)
}

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

let decodeJson = (json: Js.Json.t) => {
  switch json {
  | Js.Json.Object(root) =>
    switch Js.Dict.get(root, "name") {
    | Some(Js.Json.String(name)) =>
      switch Js.Dict.get(root, "sprites") {
      | Some(Js.Json.Object(sprites)) =>
        switch Js.Dict.get(sprites, "front_default") {
        | Some(Js.Json.String(image)) => Ok(name, image)
        | _ => Error("Has no front_default")
        }
      | _ => Error("Has no sprite node")
      }
    | _ => Error("Has no name property")
    }
  | _ => Error("Unexpected JSON")
  }
}

let unknownErrorMessage = "Unexpected error during API request"

@react.component
let make = () => {
  let (state, setState) = React.useState(() => Loading("25"))
  // Add some debouncing to typed input
  let load = ((v: string) => setState(_ => Loading(v)))->Debounce.make(~wait=500)

  React.useEffect1(() => {
    Belt.Int.fromString(getId(state))->Option.forEach(id => {
      let idAsString = Belt.Int.toString(id)
      Fetch.fetch(`https://pokeapi.co/api/v2/pokemon/${idAsString}`, {})
      ->Promise.then(
        response => {
          let code = Fetch.Response.status(response)
          if code == 200 {
            Fetch.Response.json(response)->Promise.thenResolve(decodeJson)
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
          | Ok(name, image) =>
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
  | Loading(id) => (`Loading ${id}...`, "", React.null)
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
        placeholder="Enter the number of a Pokemon"
        defaultValue={getId(state)}
        onChange={ev => ev->getEventValue->load}
      />
      <p className> {React.string(msg)} </p>
      img
    </div>
  </>
}
