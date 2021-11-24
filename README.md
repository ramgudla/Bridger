# Bridger

On DMZ server:\
1. Create directories:\
  $ mkdir -p /home/citibank/bridger/logs\
  $ mkdir -p /home/citibank/bridger/in\
  $ mkdir -p /home/citibank/bridger/out/director/archive\
  $ mkdir -p /home/citibank/bridger/out/vendor/archive

2. Extract zip file:\
  $ cd /home/citibank/bridger\
  $ unzip bridger.zip\
  $ unzip keys.zip
  $ chmod 400 id_rsa

3. Outbound and Inbound cron jobs:\
  $ crontab -e\
  ```
  */5 * * * * /home/citibank/bridger/bridger_outbound.sh BhAiInNeKeTEST 69.84.186.61 >> /home/citibank/bridger/logs/bridger_outbound.log 2>&1\
  */5 * * * * /home/citibank/bridger/bridger_inbound.sh BhAiInNeKeTESTOut 69.84.186.61 >> /home/citibank/bridger/logs/bridger_inbound.log 2>&1\
  ```
  
4. Log Rotate cron jobs:\
  $ crontab -e\
  ```
  0 2 * * * /usr/sbin/logrotate /home/citibank/bridger/bridger_outbound.conf\
  0 2 * * * /usr/sbin/logrotate /home/citibank/bridger/bridger_inbound.conf\
  ```

5. To generate keys (if u want to create new keys for production). Share the id_rsa.pub file to Bridger team to enable key based authentication.\
  $ ssh-keygen -t rsa -m PEM -f /home/citibank/bridger/id_rsa
