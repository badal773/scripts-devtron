import subprocess as sp
import psycopg2

# Establish a connection to the PostgreSQL database
# conn = psycopg2.connect(
#     host="postgresql-postgresql.devtroncd.svc.cluster.local",
#     database="orchestrator",
#     user="postgres",
#     password=""
# )

# # # Create a cursor object
# cur = conn.cursor()

# # # Execute the SQL query
# cur.execute("select deployment_app_name from pipeline where deployment_app_type='helm' and deleted=false;")

# # # Fetch all the rows returned by the query
# rows = cur.fetchall()

List=["devtroncd","devtron-demo"]

# # Print the results
# for row in rows:
#     print(row[0])
#     List.append(row[0])
# # # Close the cursor and the database connection
# cur.close()
# conn.close()


for i in List:

    kubectl_string="kubectl get secrets -A| grep 'sh.helm.release.v1."+ str(i)+"' | wc -l"

    secrets_count=sp.getoutput(kubectl_string)

    latest_revesion_string="kubectl get secrets -A -o custom-columns='SECRET:.metadata.name,revesion:.metadata.labels.version'   --sort-by=.metadata.creationTimestamp| grep 'sh.helm.release.v1."+ str(i)+"' |  tail -n 1 |  awk '{print $2}'"
    latest_revesion=sp.getoutput(latest_revesion_string)

    print(int(secrets_count))
    print(int(latest_revesion))

    secrets_count=int(secrets_count)
    latest_revesion=int(latest_revesion)

    count=int(secrets_count)

    if(count <=2 ):
        continue 
    else:
        delete= count-2
        print("we have to delete ",delete,"secrets")


        secret= "sh.helm.release.v1."+ str(i)+'.v'+str(latest_revesion)
        print(secret)
        namespace_command= "kubectl get secrets -A |grep "+secret+" |awk '{print $1}'"
        namespace=sp.getoutput(namespace_command)
        print(namespace)

        
        up_limit_to_be_delete=latest_revesion -2
        down_limit_to_be_delete=latest_revesion - secrets_count


        while(down_limit_to_be_delete<=up_limit_to_be_delete):
            kubectl_string="kubectl delete secret sh.helm.release.v1."+ str(i)+'.v'+str(up_limit_to_be_delete) + " -n "+namespace                                                                          
            print(kubectl_string)
            up_limit_to_be_delete=up_limit_to_be_delete-1



