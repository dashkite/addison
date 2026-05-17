resourceful = ( base ) ->

  class extends base

    get: -> @internal.send name: "get"

    put: ( mutator ) -> @internal.send { name: "put", mutator }

    delete: -> @internal.send name: "delete"

    post: ( builder ) -> @internal.send { name: "post", builder }

export default resourceful