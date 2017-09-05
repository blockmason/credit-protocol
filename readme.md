# Credit Protocol Smart Contracts

Ethereum Smart Contracts for the Debt Protocol dApp that faciliates debt tracking between any two parties.

## Ropsten Contract Addresses
### DPData
* 0x2f6c7dd0966f8aa217425201de970049192bfc7b

### Friend
* 0xd1c12718271eb0e02fe45eff5aa08fad7e4d372c

### Flux Capacitor
* 0xe43950c736a5b5ed6a72513d0a349e86cc3ffdb8


### security considerations for UCACs
* UCACs must verify whether they want a user to add debts between ANY two parties, or only debts they are personally involved in


## DebtData
```
0xb86341e3330abc4221552635ba20f1e6fbd41c9f
```
## FriendData
```
0x3719413d1bda8a80f3bcbba49b6c48d5de88a3d7
```
## FriendReader
```
0xc798d31b0326b666239ba264307684e5551902ae
```
## DebtReader
```
0x0eb4f311b6a5060a87377662e5b2f042471c72c8
```
## Flux
```
0x43705df4757191343b7ae24abe6d56ed07686d4f
```
## Fid
```
0x73ef61d966b60107fc21396ec61395be85972515
(idUcac)
0xeedb62eb265d2b42556ecd83324fe020d4731c19 
```


Staking notes:
Ucacs are indexed by ucacId
contain 
- ucacId (bytes32)
- ucacAddr (contract address; can be changed)
- ownerId (foundationId)


##To update:
- change ucacContract parameters in Flux to bytes32 ucacId 
