# ``Atoms``

A reactive data-binding and dependency injection library for SwiftUI x Concurrency

## Additional Resources

- [GitHub Repo](https://github.com/ra1028/swiftui-atom-properties)

## Overview

SwiftUI Atom Properties offers practical capabilities to manage the complexity of modern apps. It effectively integrates the solution for both data-binding and dependency injection while allowing us to rapidly building an application.

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
- ``AtomTestContext``
- ``AtomUpdatedContext``
- ``AtomModifierContext``

### Internal System

- ``Atom``
- ``AtomStore``
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
