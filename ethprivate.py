# Submission information for the Connecting to the Private Ethereum Blockchain HW
# https://aaronbloomfield.github.io/ccc/hws/ethprivate/

# The filename of this file must be 'ethprivate.py', else the submission
# verification routines will not work properly.

# You are welcome to have additional variables or fields in this file; you
# just can't remove variables or fields.


# Who are you?  Name and UVA userid.  The name can be in any human-readable format.
userid = "fmd3ed"
name = "Daniel Zhao"


# eth.coinbase: this is the account that you deployed the smart contracts
# (and performed any necessary transactions) for this assignment.  Be sure to
# include the leading '0x' in the address.
eth_coinbase = "0xa2b3b9e3597439e0a141e8c122cde418f15611f3"


# This dictionary contains the contract addresses of the various contracts
# that need to be deployed for this assignment.  The addresses do not need to
# be in checksummed form.  The contracts do, however, need to be deployed by
# the eth_coinbase address, above.  Be sure to include the leading '0x' in
# the address.
contracts = {

	# There are no fields required in this dictionary for this assignment

}


# This dictionary contains various information that will vary depending on the
# assignment.
other = {
	
	# This is the block number that contains the transaction where you
	# received ether from the faucet (if you did this multiple times, pick
	# one); it should be an integer.
	'faucet_txn_block_number': 130,

	# This is the transaction hash where you received ether from the faucet;
	# if you did this multiple times, use the same one as in the field above.
	# Be sure to include the leading '0x'; case does not matter.
	'faucet_txn_hash': "0x1c18efee2a003a780521542c50325fe4c3a4328fc4c503e7a2f27c28f632ee09",

	# This is the URL on the blockchain explorer that resolves to the
	# transaction (not the block!) indicated by the above transaction hash.
	# You see the blockchain explorer when you get to part 8 of the
	# assignment, and this can be filled in then.
	'faucet_txn_url': "https://andromeda.cs.virginia.edu/explorer/index.php?txn=0x1c18efee2a003a780521542c50325fe4c3a4328fc4c503e7a2f27c28f632ee09",

	# This is the block number that contains the transaction where you sent me
	# 1 (fake) ETH; it should be an integer.
	'send_txn_block_number': 143,

	# This is the transaction hash where you sent me 1 (fake) ETH.  Be sure to
	# include the leading '0x'; case does not matter.
	'send_txn_hash': "0x93b26c98cc55643805a45f28d35ae3d0d49e1751985ad3963b0c71de551b4a6b",

	# This is the URL on the blockchain explorer that resolves to the
	# transaction (not the block!) indicated by the above transaction hash.
	# You see the blockchain explorer when you get to part 8 of the
	# assignment, and this can be filled in then.
	'send_txn_url': "https://andromeda.cs.virginia.edu/explorer/index.php?txn=0x93b26c98cc55643805a45f28d35ae3d0d49e1751985ad3963b0c71de551b4a6b",

}


# These are various sanity checks, and are meant to help you ensure that you
# submitted everything that you are supposed to submit.  Other than
# submitting the necessary files to Gradescope, all other submission
# requirements are listed herein.  These values need to be changed to True
# (instead of False).
sanity_checks = {
	
	# Did you explore geth on your own?
	'explored_geth': True,

	# Did you extract the private key for your the above eth_coinbase account?
	# We are not asking for that information here, since that is private
	# information.  Only the public key (aka eth_conibase, above) is what is
	# to be included in this file.
	'extracted_private_key':  True,

	# Did you send one (fake) ETH to the course address?
	'sent_1_fake_eth':  True,

	# Did you close down geth when you were done?
	'closed_down_geth':  True,

}


# While some of these are optional, you still have to replace those optional
# ones with the empty string (instead of None).
comments = {

	# How long did this assignment take, in hours?  Please format as an
	# integer or float.
	'time_taken': 2,

	# Any suggestions for how to improve this assignment?  This part is
	# completely optional.  If none, then you can have the value here be the
	# empty string (but not None).
	'suggestions': "",

	# Any other comments or feedback?  This part is completely optional. If
	# none, then you can have the value here be the empty string (but not
	# None).
	'comments': "",
}