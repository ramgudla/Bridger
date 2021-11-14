import os
import shutil
import cx_Oracle
import csv
import requests
import xml.etree.ElementTree as ET

#export ORACLE_HOME=/Users/ramgudla/Desktop/Bugs/files/instantclient_19_8
#export LD_LIBRARY_PATH=$ORACLE_HOME

#export DYLD_LIBRARY_PATH=$ORACLE_HOME
#export PATH=$ORACLE_HOME:$PATH

#https://realpython.com/working-with-files-in-python/#copying-moving-and-renaming-files-and-directories

connstring = 'iscs_soainfra/welcome1@slc10yqy.us.oracle.com:1521/XE'
basepath = '/Users/ramgudla/Desktop/Bugs/files/tmp/'
namespaces = {'bi': 'https://support.bridgerinsight.lexisnexis.com/downloads/xsd/5.0/OutputFile.xsd'}

def update_billing(billing_no, amount):
    """
    Update new amount for a billing
    :param billing_no:
    :param amount:
    :return:
    """
    sql = ('update billing '
        'set amount = :amount '
        'where billing_no = :billing_no')

    try:
        # establish a new connection
        connection = cx_Oracle.connect(connstring)
        # create a cursor
        cursor =  connection.cursor()

        # execute the update statement
        cursor.execute(sql, [amount, billing_no])
        # commit the change
        connection.commit()
        cursor.close ()
        connection.close ()
    except cx_Oracle.Error as error:
        print(error)


def parseXML(xmlfile):

    # create element tree object
    tree = ET.parse(xmlfile)

    # get root element
    return tree.getroot()


def determineNodeListByXPath(xmlNode, xpath):

    return xmlNode.findall(xpath, namespaces)


def determineNodeByXPath(xmlNode, xpath):

    return xmlNode.find(xpath, namespaces)


def processBridgerOutputFiles():

    # List of only files
    files = [f for f in os.listdir(basepath) if os.path.isfile(os.path.join(basepath, f))]
    #files = (file for file in os.listdir(basepath) if os.path.isfile(os.path.join(basepath, file)))

    if (len(files) == 0):
        print ("No new files were found. Exiting...")
        print ('###################################')
        print ('\n')
        quit()
    print ("New Files found: ", files)
    # Loop to print each filename separately
    for filename in files:
        print("Processing file: ", filename)
        xmlNode = parseXML(os.path.join(basepath, filename))

        #entities = determineNodeListByXPath(xmlNode, "./{https://support.bridgerinsight.lexisnexis.com/downloads/xsd/5.0/OutputFile.xsd}Entity/{https://support.bridgerinsight.lexisnexis.com/downloads/xsd/5.0/OutputFile.xsd}GeneralInfo")
        matchedNodes = determineNodeListByXPath(xmlNode, "./bi:Entity/bi:WatchList/bi:Match")
        result = determineNodeByXPath(matchedNodes[0], "bi:EntityScore").text
        print ("Result: ", result)
        #update_billing (1, result)

        # archive file
        print ("Archiving File: ", filename)
        shutil.move(os.path.join(basepath, filename), os.path.join(basepath, 'archive'))


def main():

    processBridgerOutputFiles()
    print ('###################################')
    print ('\n')

######### main function ######
if __name__ == '__main__':
    main()
