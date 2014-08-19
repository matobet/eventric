describe 'Remote Feature', ->
  exampleContext  = null
  doSomethingStub = null
  beforeEach (done) ->
    doSomethingStub = sandbox.stub()

    exampleContext = eventric.context 'Example'
    exampleContext.defineDomainEvents
      ExampleCreated: ->

    exampleContext.addCommandHandlers
      CreateExample: (params, callback) ->
        @$repository('Example').create()
        .then (exampleId) =>
          @$repository('Example').save exampleId
      DoSomething: (params, callback) ->
        doSomethingStub()
        callback()

    class Example
      create: (callback) ->
        @$emitDomainEvent 'ExampleCreated'
        callback()
    exampleContext.addAggregate 'Example', Example

    exampleContext.addQueryHandlers
      getSomething: (params, callback) ->
        callback null, 'something'

    exampleContext.initialize ->
      done()


  describe 'given we created and initialized some example context', ->
    it 'then it should be able to receive commands over a remote', (done) ->
      exampleRemote = eventric.remote 'Example'
      exampleRemote.command 'DoSomething'
      .then ->
        expect(doSomethingStub).to.have.been.calledOnce
        done()


    it 'then it should be able to answer queries over a remote', (done) ->
      exampleRemote = eventric.remote 'Example'
      exampleRemote.query 'getSomething'
      .then (result) ->
        expect(result).to.equal 'something'
        done()


    it 'then it should be possible to subscribe to domain events and receive them', (done) ->
      exampleRemote = eventric.remote 'Example'

      numberOfReceivedEvents = 0
      exampleRemote.subscribeToDomainEvent 'ExampleCreated', ->
        numberOfReceivedEvents++
        if numberOfReceivedEvents is 2
          done()

      exampleRemote.command 'CreateExample', {}
      exampleRemote.command 'CreateExample', {}


    it 'then it should be possible to unsubscribe from domain events', (done) ->
      exampleRemote = eventric.remote 'Example'
      firstHandler = sandbox.stub()
      exampleRemote.subscribeToDomainEvent 'ExampleCreated', firstHandler
      exampleRemote.unsubscribeFromDomainEvent 'ExampleCreated', firstHandler
      exampleRemote.subscribeToDomainEvent 'ExampleCreated', ->
        expect(firstHandler).not.to.have.been.called
        done()
      exampleRemote.command 'CreateExample', {}


  describe 'given we created and initialized some example context with a custom remote endpoint', ->
    customRemoteBridge = null
    beforeEach ->
      class CustomRemoteEndpoint
        constructor: ->
          customRemoteBridge = (rpcRequest) =>
            @_handleRPCRequest rpcRequest

        setRPCHandler: (@_handleRPCRequest) ->

      eventric.addRemoteEndpoint 'custom', new CustomRemoteEndpoint


    it 'then it should be able to receive commands over the custom remote client', (done) ->
      class CustomRemoteClient
        rpc: (rpcRequest, callback) ->
          customRemoteBridge rpcRequest
          callback()

      exampleRemote = eventric.remote 'Example'
      exampleRemote.addClient 'custom', new CustomRemoteClient
      exampleRemote.set 'default client', 'custom'
      exampleRemote.command 'DoSomething'
      .then ->
        expect(doSomethingStub).to.have.been.calledOnce
        done()
