FROM python:3.6.5
MAINTAINER Daniel Domingo Fernandez "daniel.domingo.fernandez@scai.fraunhofer.de"

RUN apt-get update
RUN apt-get -y upgrade && apt-get -y install vim p7zip-full

RUN mkdir /home/pathme_viewer /data /data/logs /home/pathme /home/pathme/.pathme

# Create databases folders (user has no permission to do so)
RUN mkdir /home/pathme/.pathme/kegg /home/pathme/.pathme/kegg/cache /home/pathme/.pathme/kegg/xml /home/pathme/.pathme/kegg/bel
RUN mkdir /home/pathme/.pathme/reactome /home/pathme/.pathme/reactome/rdf /home/pathme/.pathme/reactome/bel
RUN mkdir /home/pathme/.pathme/wikipathways /home/pathme/.pathme/wikipathways/rdf /home/pathme/.pathme/wikipathways/bel

# Create pathme user
RUN groupadd -r pathme && useradd --no-log-init -r -g pathme pathme

# permission pathme user
RUN chown -R pathme /home/pathme_viewer && chgrp -R pathme /home/pathme_viewer
RUN chown -R pathme /home/pathme && chgrp -R pathme /home/pathme

RUN pip3 install --upgrade pip
RUN pip3 install gunicorn

COPY . /opt/pathme_viewer
WORKDIR /opt/pathme_viewer

# Add permission to edit folders
RUN chown -R pathme /opt/pathme_viewer && chgrp -R pathme /opt/pathme_viewer && chmod +x /opt/pathme_viewer/src/bin/*
RUN chown -R pathme /home/pathme/.pathme/ && chgrp pathme -R /home/pathme/.pathme/ && chmod +x /home/pathme/.pathme/*
RUN chown -R pathme /data && chgrp -R pathme /data

# How to Zip a file: Go inside the folder "bel" make sure there are only pickles and run-> zip -r bel.zip . -x ".*" -x "__MACOSX"
# TODO: When zipping files in macOS: https://apple.stackexchange.com/questions/239578/compress-without-ds-store-and-macosx

# Download KEGG pickles (Update link if the file is replaced)
ADD https://drive.google.com/uc?authuser=0&id=1a_6lck28Df9v2E-Dt45-ZARsdGVs-V9s&export=download /home/pathme/.pathme/kegg/bel.zip
RUN 7z x /home/pathme/.pathme/kegg/bel.zip -o/home/pathme/.pathme/kegg/

# Download Reactome pickles (Update link if the file is replaced)
ADD https://owncloud.scai.fraunhofer.de/index.php/s/EKkJmrXnGr2rwd6/download /home/pathme/.pathme/reactome/bel.zip
RUN 7z x /home/pathme/.pathme/reactome/bel.zip -o/home/pathme/.pathme/reactome

# Download WikiPathways pickles (Update link if the file is replaced)
ADD https://drive.google.com/uc?authuser=0&id=1adwTE9cUpMb0lFiN0gbrGLaWfExtFdux&export=download /home/pathme/.pathme/wikipathways/bel.zip
RUN 7z x /home/pathme/.pathme/wikipathways/bel.zip -o/home/pathme/.pathme/wikipathways/

# Remove downloaded files
RUN rm /home/pathme/.pathme/kegg/bel.zip && rm /home/pathme/.pathme/reactome/bel.zip && rm /home/pathme/.pathme/wikipathways/bel.zip

# Install PathMe-Viewer module
RUN pip3 install .

# Add --user python modules to PATH
ENV PATH="/home/pathme_viewer/.local/bin:$PATH"

# TODO: Change me in order to export to a different port
EXPOSE 5000

USER pathme

# Load data
RUN python3 -m pathme_viewer manage load --yes

ENTRYPOINT ["/opt/pathme_viewer/src/bin/bootstrap.sh"]
