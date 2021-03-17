Komodo Node version: 1.0.0
Start new wallet
$ komodo.bat
Import your private key
$ komodo.bat privkey=DO_NOT_USE_UqSQTEDpDXbhjTLZeaP2cN499ApAiYRUV4wgQjT87BQmdHKwPWoe
example command
$ komodo-cli.exe -ac_name=VLB1 "-datadir=blockchain_data/VLB1" "-conf=VLB1.conf" getinfo

Structure 
komodo-node
│   fetch-params.bat
│   komodo-cli.exe
│   komodo-tx.exe
│   komodo.bat
│   komodod.exe
│   README.md
│   VLB1_7776
│   wget64.exe
│
├───exports
│
├───blockchain_data
│   └───VLB1
│       │   .lock
│       │   address.txt
│       │   db.log
│       │   debug.log
│       │   fee_estimates.dat
│       │   komodostate
│       │   pubkey.txt
│       │   VLB1.conf
│       │   wallet.dat
│       │   
│       ├───blocks
│       │   │   blk00000.dat
│       │   │   rev00000.dat
│       │   │   
│       │   └───index
│       │           000003.log
│       │           CURRENT
│       │           LOCK
│       │           LOG
│       │           MANIFEST-000002
│       │           
│       ├───chainstate
│       │       000003.log
│       │       CURRENT
│       │       LOCK
│       │       LOG
│       │       MANIFEST-000002
│       │       
│       ├───database
│       │       log.0000000001
│       │       
│       └───notarisations
│               000003.log
│               CURRENT
│               LOCK
│               LOG
│               MANIFEST-000002
│               
└───public_params
        sapling-output.params
        sapling-spend.params
        sprout-groth16.params
        sprout-proving.key
        sprout-verifying.key