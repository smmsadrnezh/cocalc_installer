FROM sagemathinc/cocalc-docker:latest

RUN apt update -y
RUN apt install -y texlive texlive-latex-recommended texlive-xetex texlive-lang-arabic texlive-lang-english texlive-pictures texlive-latex-extra texlive-extra-utils texlive-fonts-recommended texlive-pstricks
