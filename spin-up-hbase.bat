cd namenode
docker pull fhirfactory/pegacorn-base-hadoop:1.0.0
docker build --rm --build-arg IMAGE_BUILD_TIMESTAMP="%date% %time%" -t pegacorn-fhirplace-namenode:1.0.0-snapshot --file Dockerfile .
helm upgrade pegacorn-fhirplace-namenode-site-a --install --namespace site-a --set serviceName=pegacorn-fhirplace-namenode,hostPathNamenode=/data/hadoop-namenode,clusterName=Pegacorn,imageTag=1.0.0-snapshot,numOfPods=1 helm
timeout 60
cd ..\datanode
docker build --rm --build-arg IMAGE_BUILD_TIMESTAMP="%date% %time%" -t pegacorn-fhirplace-datanode:1.0.0-snapshot --file Dockerfile .
helm upgrade pegacorn-fhirplace-datanode-alpha-site-a --install --namespace site-a --set serviceName=pegacorn-fhirplace-datanode-alpha,hostPathDatanode=/data/hadoop-datanode-alpha,imageTag=1.0.0-snapshot,numOfPods=1 helm
helm upgrade pegacorn-fhirplace-datanode-beta-site-a --install --namespace site-a --set serviceName=pegacorn-fhirplace-datanode-beta,hostPathDatanode=/data/hadoop-datanode-beta,imageTag=1.0.0-snapshot,numOfPods=1 helm
timeout 30
cd ..\zookeeper
docker pull fhirfactory/pegacorn-base-zookeeper:1.0.0
docker build --rm --build-arg IMAGE_BUILD_TIMESTAMP="%date% %time%" -t pegacorn-fhirplace-zookeeper:1.0.0-snapshot --file Dockerfile .
helm upgrade pegacorn-fhirplace-zookeeper-site-a --install --namespace site-a --set serviceName=pegacorn-fhirplace-hbase-zookeeper,imagePullPolicy=Never,basePort=32310,hostPathZKData=/data/zookeeper-data,imageTag=1.0.0-snapshot,numOfPods=1 helm
timeout 60
cd ..\hmaster
docker pull fhirfactory/pegacorn-base-hbase:1.0.0
docker build --rm --build-arg IMAGE_BUILD_TIMESTAMP="%date% %time%" -t pegacorn-fhirplace-hbase-master:1.0.0-snapshot --file Dockerfile .
helm upgrade pegacorn-fhirplace-hbase-master-site-a --install --namespace site-a --set serviceName=pegacorn-fhirplace-hbase-master,imagePullPolicy=Never,basePort=32410,hostPathHbMaster=/data/hbase-master,imageTag=1.0.0-snapshot,numOfPods=1 helm
timeout 30
cd ..\hregionserver
docker build --rm --build-arg IMAGE_BUILD_TIMESTAMP="%date% %time%" -t pegacorn-fhirplace-hbase-region:1.0.0-snapshot --file Dockerfile .
helm upgrade pegacorn-fhirplace-hbase-region-site-a --install --namespace site-a --set serviceName=pegacorn-fhirplace-hbase-region,imagePullPolicy=Never,basePort=32210,hostPathHbRegion=/data/hbase-region,imageTag=1.0.0-snapshot,numOfPods=2 helm
