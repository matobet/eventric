DomainEvent = require 'eventric/domain_event'
domainEventIdGenerator = require './domain_event_id_generator'
logger = require 'eventric/logger'

class Aggregate

  constructor: (@_context, @_name, AggregateClass) ->
    @_domainEvents = []
    @instance = new AggregateClass
    @instance.$emitDomainEvent = @emitDomainEvent


  setId: (@id) ->
    @instance.$id = @id


  emitDomainEvent: (domainEventName, domainEventPayload) =>
    aggregate =
      id: @id
      name: @_name

    domainEvent = @_createDomainEvent domainEventName, domainEventPayload, aggregate
    @_domainEvents.push domainEvent

    @_handleDomainEvent domainEventName, domainEvent
    logger.debug "Created and Handled DomainEvent in Aggregate", domainEvent


  _createDomainEvent: (domainEventName, domainEventConstructorParams, aggregate) ->
    DomainEventPayloadConstructor = @_context.getDomainEventPayloadConstructor domainEventName

    if !DomainEventPayloadConstructor
      throw new Error "Tried to create domain event '#{domainEventName}' which is not defined"

    payload = {}
    DomainEventPayloadConstructor.apply payload, [domainEventConstructorParams]

    new DomainEvent
      id: domainEventIdGenerator.generateId()
      name: domainEventName
      aggregate: aggregate
      context: @_context.name
      payload: payload


  _handleDomainEvent: (domainEventName, domainEvent) ->
    if @instance["handle#{domainEventName}"]
      @instance["handle#{domainEventName}"] domainEvent


  getDomainEvents: ->
    @_domainEvents


  applyDomainEvents: (domainEvents) ->
    @_applyDomainEvent domainEvent for domainEvent in domainEvents


  _applyDomainEvent: (domainEvent) ->
    @_handleDomainEvent domainEvent.name, domainEvent


module.exports = Aggregate
