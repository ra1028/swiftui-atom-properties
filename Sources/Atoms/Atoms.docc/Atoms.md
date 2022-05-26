# ``Atoms``

A Reactive Data-Binding and Dependency Injection Library for SwiftUI x Concurrency.

## Overview

SwiftUI Atom Properties offers practical capabilities to manage the complexity of modern apps. It effectively integrates the solution for both data-binding and dependency injection while allowing us to rapidly building an application.

## Source Code

<https://github.com/ra1028/swiftui-atom-properties>

## Topics

### Atoms

- ``ValueAtom``
- ``StateAtom``
- ``TaskAtom``
- ``ThrowingTaskAtom``
- ``AsyncSequenceAtom``
- ``PublisherAtom``
- ``ObservableObjectAtom``

### Modifiers

- ``Atom/select(_:)``
- ``Atom/phase``

### Attributes

- ``KeepAlive``

### Property Wrappers

- ``Watch``
- ``WatchState``
- ``WatchStateObject``
- ``ViewContext``

### Contexts

- ``AtomContext``
- ``AtomWatchableContext``
- ``AtomRelationContext``
- ``AtomViewContext``
- ``AtomTestContext``

### Views

- ``AtomRoot``
- ``AtomRelay``
- ``Suspense``

### Values

- ``AsyncPhase``

### Debugging

- ``AtomObserver``
- ``AtomHistory``
- ``Snapshot``

### Internal System

- ``Atom``
- ``SelectModifierAtom``
- ``TaskPhaseModifierAtom``
- ``AtomHook``
- ``AtomStateHook``
- ``AtomTaskHook``
- ``AtomRefreshableHook``
- ``AtomHookContext``
- ``ValueHook``
- ``StateHook``
- ``TaskHook``
- ``ThrowingTaskHook``
- ``AsyncSequenceHook``
- ``PublisherHook``
- ``ObservableObjectHook``
- ``SelectModifierHook``
- ``TaskPhaseModifierHook``
