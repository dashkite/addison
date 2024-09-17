Storage =

  get: ( key ) ->
    if ( item = localStorage.getItem key )?
      JSON.parse item
    else {}

  set: ( key, value ) ->
    if value?
      localStorage.setItem key, JSON.stringify value
    else
      localStorage.removeItem key

  has: ( key ) -> ( Storage.get key  )?

export default Storage