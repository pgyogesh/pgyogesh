import sqlite3
import sys

# Get file from first argument
conn = sqlite3.connect(sys.argv[1])
cursor = conn.cursor()
cursor.execute("SELECT DISTINCT tablet_uuid FROM leaderless")
listOfLeaderlessTablets = []
for row in cursor.fetchall():
    listOfLeaderlessTablets.append(row[0])
print(listOfLeaderlessTablets)

# Tables
# leaderless(tablet_uuid,replicas,namespace,table_name,node_uuid,status,ip,leader_count)
# ENT_TABLET(id TEXT ,table_id,state,is_leader,server_uuid,server_addr,type);
# tablet(node_uuid,tablet_uuid TEXT , table_name,table_uuid, namespace,state,status, start_key, end_key, sst_size INTEGER, wal_size INTEGER, cterm, cidx, leader, lease_status);

scriptFile = open('leaderless_fixer.sh', 'w')
scriptFile.write("#!/bin/bash\n")
scriptFile.write("# This script will delete the tablet on bad node and remote bootstrap the leader to the bad node.\n")
scriptFile.write("export TLS_DIR='--certs_dir_name=/home/yugabyte/yugabyte-tls-config'\n")
scriptFile.write("export YB_BIN='/home/yugabyte/tserver/bin'\n")
deleteReason = "Bad Tablet - Leaderless"

def verifyOpID(tablet,leaderUUID, replicaUUID):
    # get leader's term and id from tablet
    getLeaderTermQuery = "SELECT cterm FROM tablet WHERE tablet_uuid = '" + tablet + "' AND node_uuid = '" + leaderUUID + "'"
    cursor.execute(getLeaderTermQuery)
    try:
        leaderTerm = int(cursor.fetchone()[0])
    except TypeError:
        leaderTerm = 0
    getLeaderIdQuery = "SELECT cidx FROM tablet WHERE tablet_uuid = '" + tablet + "' AND node_uuid = '" + leaderUUID + "'"
    cursor.execute(getLeaderIdQuery)
    try:
        leaderId = int(cursor.fetchone()[0])
    except TypeError:
        leaderId = 0

    # get replica's term and id from tablet
    getReplicaTermQuery = "SELECT cterm FROM tablet WHERE tablet_uuid = '" + tablet + "' AND node_uuid = '" + replicaUUID + "'"
    cursor.execute(getReplicaTermQuery)
    try:
        replicaTerm = int(cursor.fetchone()[0])
    except TypeError:
        replicaTerm = 0
    getReplicaIdQuery = "SELECT cidx FROM tablet WHERE tablet_uuid = '" + tablet + "' AND node_uuid = '" + replicaUUID + "'"
    cursor.execute(getReplicaIdQuery)
    try:    
        replicaId = int(cursor.fetchone()[0])
    except TypeError:
        replicaId = 0
    
    LeaderOpID = str(leaderTerm) + "." + str(leaderId)
    ReplicaOpID = str(replicaTerm) + "." + str(replicaId)
        
    # compare terms and ids
    if leaderTerm > replicaTerm:
        return True, LeaderOpID, ReplicaOpID
    elif leaderTerm == replicaTerm and leaderId > replicaId:
        return True, LeaderOpID, ReplicaOpID
    elif leaderTerm == replicaTerm and leaderId == replicaId:
        print(f"Skipping {tablet} because leader's OpID is equal to replica's OpID. Need to investigate why leader is not getting the lease.")
        return False, LeaderOpID, ReplicaOpID
    else:
        return False, LeaderOpID, ReplicaOpID

for tablet in listOfLeaderlessTablets:
    # get tablet's leader from ENT_TABLET
    getLeaderUUIDQuery = "SELECT server_uuid FROM ENT_TABLET WHERE id = '" + tablet + "' AND is_leader"
    cursor.execute(getLeaderUUIDQuery)
    leaderUUID = cursor.fetchone()[0]
    
    # get tablet's replicas from ENT_TABLET
    getReplicaAddrQuery = "SELECT server_addr,server_uuid FROM ENT_TABLET WHERE id = '" + tablet + "' AND not is_leader"
    cursor.execute(getReplicaAddrQuery)
    replicaRow = cursor.fetchone()
    replicaServerAddr = replicaRow[0]
    replicaUUID = replicaRow[1]
    isGood, leaderOpID, ReplicaOpID = verifyOpID(tablet,leaderUUID,replicaUUID)
    if isGood:
        scriptFile.write(f"# Leader OpID: {leaderOpID}    Replica OpID: {ReplicaOpID}\n")
        scriptFile.write(f"$YB_BIN/yb-ts-cli $TLS_DIR --server_address={replicaServerAddr} delete_tablet {tablet} '{deleteReason}'\n")
        scriptFile.write(f"$YB_BIN/yb-ts-cli $TLS_DIR --server_address={replicaServerAddr} remote_bootstrap {leaderUUID} {tablet}\n")
    else:
        print(f"Skipping {tablet} because leader's OpID is not greater than replica's OpID")
scriptFile.close()