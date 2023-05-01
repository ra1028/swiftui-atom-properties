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
- ``ModifiedAtom``

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

### Views

- ``AtomRoot``
- ``AtomScope``
- ``Suspense``

### Values

- ``AsyncPhase``
- ``Snapshot``

### Contexts

- ``AtomContext``
- ``AtomWatchableContext``
- ``AtomTransactionContext``
- ``AtomViewContext``
- ``AtomUpdatedContext``
- ``AtomTestContext``

### Internal System

- ``Atom``
- ``AtomModifier``
- ``SelectModifier``
- ``TaskPhaseModifier``
- ``AtomLoader``
- ``RefreshableAtomLoader``
- ``AsyncAtomLoader``
- ``ValueAtomLoader``
- ``StateAtomLoader``
- ``TaskAtomLoader``
- ``ThrowingTaskAtomLoader``
- ``AsyncSequenceAtomLoader``
- ``PublisherAtomLoader``
- ``ObservableObjectAtomLoader``
- ``ModifiedAtomLoader``
- ``AtomLoaderContext``
