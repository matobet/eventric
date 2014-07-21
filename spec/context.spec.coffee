describe 'Context', ->
  Context = null

  class RepositoryMock

  HelperUnderscoreMock =
    extend: sandbox.stub()

  aggregateServiceStub = null
  eventricMock = null

  beforeEach ->
    eventBusStub =
      subscribeToDomainEvent: sandbox.stub()

    aggregateServiceStub =
      initialize: sandbox.stub()

    eventricMock =
      require: sandbox.stub()
      get: sandbox.stub()
    eventricMock.require.withArgs('AggregateService').returns sandbox.stub().returns aggregateServiceStub
    eventricMock.require.withArgs('EventBus').returns sandbox.stub().returns eventBusStub
    eventricMock.require.withArgs('Repository').returns RepositoryMock
    eventricMock.require.withArgs('HelperUnderscore').returns HelperUnderscoreMock
    eventricMock.require.withArgs('HelperAsync').returns eventric.require 'HelperAsync'
    eventricMock.require.withArgs('StoreInMemory').returns eventric.require 'StoreInMemory'
    mockery.registerMock 'eventric', eventricMock

    Context = eventric.require 'Context'


  describe '#initialize', ->

    it 'should throw an error if neither a global nor a custom event store was configured', ->
      context = new Context
      expect(context.initialize).to.throw Error


    it 'should instantiate all registered projections', (done) ->
      context = new Context
      ProjectionStub = sandbox.stub()
      context.addProjection 'SomeProjection', ProjectionStub
      context.initialize =>
        expect(ProjectionStub).to.have.been.calledWithNew
        done()


    it 'should instantiate and initialize all registered adapters', (done) ->
      context = new Context
      AdapterFactory = sandbox.stub()
      context.addAdapter 'Adapter', AdapterFactory
      context.initialize =>
        expect(AdapterFactory).to.have.been.calledWithNew
        done()


  describe '#command', ->
    describe 'given the command has no registered handler', ->
      it 'should call the callback with a command not found error', (done) ->
        someContext = new Context
        someContext.initialize =>

          command =
            name: 'doSomething'
            params:
              id: 42
              foo: 'bar'

          callback = sinon.spy()

          someContext.command command, callback
          expect(callback.calledWith sinon.match.instanceOf Error).to.be.true
          done()


    describe 'has a registered handler', ->
      it 'should execute the command handler', (done) ->
        commandStub = sandbox.stub()
        someContext = new Context
        someContext.initialize =>
          someContext.addCommandHandler 'doSomething', commandStub

          command =
            name: 'doSomething'
            params:
              foo: 'bar'

          someContext.command command, ->
          expect(commandStub.calledWith command.params, sinon.match.func).to.be.true
          done()


  describe '#query', ->
    someContext = null
    beforeEach ->
      someContext = new Context

    describe 'given the query has no matching queryhandler', ->
      it 'should callback with an error', (done) ->
        someContext.initialize =>
          someContext.query
            name: 'getSomething'
          .catch (error) ->
            expect(error).to.be.an.instanceOf Error
            done()


    describe 'given the query has a matching queryhandler', ->
      it 'should call the queryhandler function', (done) ->
        queryStub = sandbox.stub().yields null, 'result'
        someContext.addQueryHandler 'getSomething', queryStub
        someContext.initialize =>
          someContext.query
            name: 'getSomething'
          .then (result) ->
            expect(result).to.equal 'result'
            expect(queryStub).to.have.been.calledWith
            done()
