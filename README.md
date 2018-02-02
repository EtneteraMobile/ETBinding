# LiveData for iOS

[![Version](https://img.shields.io/cocoapods/v/ETLiveData.svg?style=flat)](http://cocoapods.org/pods/ETLiveData)
[![License](https://img.shields.io/cocoapods/l/ETLiveData.svg?style=flat)](http://cocoapods.org/pods/ETLiveData)
[![Platform](https://img.shields.io/cocoapods/p/ETLiveData.svg?style=flat)](http://cocoapods.org/pods/ETLiveData)



*Inspired by [LiveData](https://developer.android.com/topic/libraries/architecture/livedata.html) from Android Architecture Components.*

------

LiveData is an observable data holder class. Unlike a regular observable, LiveData is lifecycle-aware, meaning it respects the lifecycle of its owner. This awareness ensures LiveData only updates app component observers that are in an active lifecycle state.

You can register an observer paired with an object that is LifecycleOwner (typealias for AnyObject). This relationship allows the observer to be removed when the state of the corresponding Lifecycle object changes to deallocated. This is especially useful for view controllers because they can safely observe LiveData objects and not worry about leaks.

### Advantages of using LiveData

#### No memory leaks

Observers are bound to lifecycle objects and clean up after themselves when their associated lifecycle is destroyed.

#### Safe [unowned self]

Because Observer is bound to lifecycle, it will never happens that observer is updated if lifecycle owner is deallocated.

#### No more manual lifecycle handling

UI components just observe relevant data and don’t stop observation. LiveData automatically manages this since it’s aware of the relevant lifecycle status changes while observing.

## Installation

### CocoaPods

Add `pod 'ETLiveData'` to your Podfile.

### Carthage

Add `github "EtneteraMobile/ETLiveData"` to your Cartfile.

## Class diagram

![Class diagram](Resources/scheme.pdf)

## Usage

Follow these steps to work with LiveData objects:

1. Create an instance of LiveData to hold a certain type of data. This is usually done within your ViewModel class.
2. Create an Observer object that defines the update closure, which controls what happens when the LiveData object's held data changes. You usually create an Observer object in a view controller.
3. Attach the Observer object to the LiveData object using the observe() method. The observe() method takes a LifecycleOwner object. This subscribes the Observer object to the LiveData object so that it is notified of changes.

**Note:** You can register an observer without an associated LifecycleOwner object using the [`observeForever`](#observe-forever) method. In this case, the observer is considered to be always active and is therefore always notified about modifications. You can remove these observers calling the [`removeObserver`](#remove-observer) method.

When you update the value stored in the LiveData object, it triggers all registered observers as long as the attached LifecycleOwner is in the active state.

### Observe with lifecycle owner

Observation starts only with owner and update closure, then new instance of `Observer` is returned. This observer can be ignored in case when future remove isn't needed.

```swift
let liveData: LiveData<String> = LiveData()
let observer = liveData.observe(owner: self) { data in
	// do something with data
}
// observer can be used for later unregistration
```



Update closure can be encapsulated inside `Observer` and after then registered. This pattern is used when observation is started in future.

```swift
let observer: Observer<String?> = Observer(update: { data in
	// do something with data
})
// … and later
let liveData: LiveData<String> = LiveData()
liveData.observe(owner: self, observer: observer)
// observer can be used for later unregistration
```

### Observe forever

Lifecycle owner isn't mandatory all the time. When owner isn't given, unregistration is under your control.

```swift
let liveData: LiveData<String> = LiveData()
let observer = liveData.observeForever { data in
	// do something with data
}
// observer can be used for later unregistration
```

```swift
let observer: Observer<String?> = Observer(update: { data in
	// do something with data
})
// … and later
let liveData: LiveData<String> = LiveData()
liveData.observeForever(observer: observer)
// observer can be used for later unregistration
```

### Remove observer

Unregisters given observer from liveData changes observation.

```swift
// … observer is obtained from early called function `observe`
liveData.remove(observer: observer)
```

### Dispatch value to observers

After observation is started value isn't automatically dispatched to observer. If you want to gain current value, you can read it directly from `data` variable or you can call `dispatch` and update will be delivered to newly registered observers.

```swift
// Dispatches value to observers that were registered from last dispatch
liveData.dispatch()

// Dispatches value to given observer if is newly registered from last dispatch
liveData.dispatch(initiator: observer)
```

Every **observer is called only once per new value although `dispatch` is called multiple times**. Value setter is versioned and observer holds last delivered value version and blocks dispatching of version that was already delivered.

## Contributing

Contributions to ETLiveData are welcomed and encouraged!

## License

ETLiveData is available under the MIT license. See [LICENSE](LICENSE) for more information.

## Attributions

I've used [SwiftPlate](https://github.com/JohnSundell/SwiftPlate) to generate xcodeproj compatible with CocoaPods and Carthage.