# Bridger

#!/bin/bash

#gpg --local-user appltest -a --encrypt --recipient PPGP_GXS_2048 $1

#gpg --local-user AIRTEL_BRIDGER -a --encrypt --recipient bridger-us-stag@LexisNexisRisk.com ASI_Supplier_details_070121.txt $1

#gpg --batch --yes -u anil.patchava@adktechnologies.com --output $1.pgp --passphrase=airtel@123% --recipient sysadmin@boa.mg --sign --encrypt $1

#mv $1.asc $2

#mv $1 $3

# https://blog.ghostinthemachines.com/2015/03/01/how-to-use-gpg-command-line/
# gpg --full-generate-key

# gpg --list-keys
# gpg --list-secret-keys
#
# export and import keys
# gpg --output public.pgp --armor --export ramakrishna.g@adktechnologies.com
# gpg --output private.pgp --armor --export-secret-key ramakrishna.g@adktechnologies.com
# gpg --output private.pgp --export-secret-key AIRTEL_BRIDGER


# import public key
# gpg --import mary-geek-public.key
# gpg --delete-key key-ID
# gpg --delete-key "User Name"
# gpg --delete-secret-key key-ID
# gpg --delete-secret-key "User Name"

# verify and sign the key
# gpg --fingerprint mary-geek@protonmail.com
# gpg --sign-key mary-geek@protonmail.com

# encrypt and decrypt
# gpg --encrypt --sign --armor -r mary-geek@protonmail.com
# gpg --decrypt coded.asc > plain.txt

# trust the key
gpg --edit-key YOUR@KEY.ID
gpg>trust
# or
You can use the --always-trust flag to skip this message.

gpg –encrypt --always-trust -r bridger-us-stag@LexisNexisRisk.com ASI_Director_details_27092021.txt

#Bridger
gpg --import BridgerInsightXG.asc
gpg --encrypt --armor -r bridger-us-stag@LexisNexisRisk.com ASI_Director_details_27092021.txt
