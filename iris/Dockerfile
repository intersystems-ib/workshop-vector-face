ARG IMAGE=containers.intersystems.com/intersystems/iris-community:2024.1-preview
FROM $IMAGE

USER root

WORKDIR /opt/irisapp
RUN chown -R irisowner:irisowner /opt/irisapp

RUN apt-get update && apt-get install -y python3

RUN apt-get update && \
    apt-get install -y libgl1-mesa-glx libglib2.0-0

# install required packages
COPY --chown=$ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISGROUP /requirements.txt /
RUN chmod 777 /requirements.txt

RUN pip3 install -r /requirements.txt

USER irisowner

# copy files to image
WORKDIR /opt/irisapp
COPY --chown=irisowner:irisowner /iris/src src

COPY --chown=$ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISGROUP /iris/irissession.sh /
RUN chmod +x /irissession.sh

COPY --chown=$ISC_PACKAGE_MGRUSER:$ISC_PACKAGE_IRISGROUP /iris/webapp.xml /
RUN chmod +x /webapp.xml

SHELL ["/irissession.sh"]

RUN \
  zn "USER" \
  set sc = $SYSTEM.OBJ.LoadDir("/opt/irisapp/src/Installer", "ck", , 1) \
  if sc do ##class(Vectorface.Installer).Install() \
  zn "VECTORFACE" \
  set sc = $SYSTEM.OBJ.LoadDir("/opt/irisapp/src/Vectorface", "ck", , 1) \
  # set production = "Vectorface.Production" \
  # set ^Ens.Configuration("csp","LastProduction") = production \
  # do ##class(Ens.Director).SetAutoStart(production)