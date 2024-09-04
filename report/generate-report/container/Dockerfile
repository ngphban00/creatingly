FROM ubuntu:latest

# Install mailutils, ssmtp and pdflatex
RUN apt-get update && apt-get install -y \
    mailutils \
    ssmtp \
    gettext-base \
    texlive-latex-base \
    texlive-fonts-recommended \
    texlive-fonts-extra

# Copy the template config file
COPY ssmtp.conf.template /etc/ssmtp/ssmtp.conf.template

COPY generate-and-report.sh /generate-and-report.sh
COPY grafana-reporter /grafana-reporter

# Make the command/scripts executable
RUN chmod +x /generate-and-report.sh
RUN chmod +x /grafana-reporter

