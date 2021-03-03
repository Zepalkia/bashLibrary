source ../bashLibrary.sh


testing_testCase "XML creation" << TEST
assertSuccess xml_create XML /tmp/configuration.xml xml
assertSuccess xml_dump XML
TEST

XML=""
value=""
value1=""

testing_testCase "XML element handling" << TEST
assertSuccess xml_load XML "/tmp/configuration.xml"
assertFailure xml_getSingleValue XML "xml.values.value0" value
assertFailure xml_addNode XML "xml.values.value0" ""
assertSuccess xml_addNode XML "xml.values" ""
assertSuccess xml_addNode XML "xml.values.value0" "0"
assertSuccess xml_addNode XML "xml.values.value1" "10"
assertSuccess xml_getSingleValue XML "xml.values.value1" value
assertEqual \$value 10
assertSuccess xml_setSingleValue XML "xml.values.value1" 11
assertSuccess xml_getSingleValue XML "xml.values.value1" value
assertEqual \$value 11
TEST

attributes=("atr1=1" "atr2=2")
xml_addNode XML "xml.newValues" "" attributes
testing_testCase "XML attribute handling" << TEST
assertSuccess xml_addNode XML "xml.newValues.nv0" 0 attributes
assertSuccess xml_getSingleValue XML "xml.newValues@atr1" value
assertSuccess xml_getSingleValue XML "xml.newValues.nv0@atr1" value1
assertEqual \$value \$value1
assertSuccess xml_setSingleValue XML "xml.newValues.nv0@atr1" 2
assertSuccess xml_getSingleValue XML "xml.newValues.nv0@atr1" value
assertSuccess xml_getSingleValue XML "xml.newValues.nv0@atr2" value1
assertEqual \$value \$value1
assertSuccess xml_dump XML
TEST

XML=""
xmllint --format /tmp/configuration.xml > /tmp/configuration2.xml

mv /tmp/configuration2.xml /tmp/configuration.xml
testing_testCase "XML reformat compatibility" << TEST
assertSuccess xml_load XML /tmp/configuration.xml
assertSuccess xml_getSingleValue XML "xml.newValues.nv0@atr1" value
assertSuccess xml_getSingleValue XML "xml.newValues.nv0@atr2" value1
assertEqual \$value \$value1
TEST

