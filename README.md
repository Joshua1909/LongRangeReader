# Weaponised Reader

Adapting the [Linuz](https://github.com/linuz/LongRangeReader) project, this sets up a HID long range RFID reader to wirelessly clone badges HID badges. This extends the functionality, to allow reading and writing of cards in the field. The build includes two devices, one Raspberry Pi Zero W attaches to the HID Long Range Reader to interpret and store card data. The other Pi Zero W attaches to the Proxmark, and is used to run a webserver and run the clone commands in the field.

Hardware Needed

  * **Long Range Reader** - Maxiprox 5375 or R90
  * **Raspberry Pi Zero W** - Attached to the Long Range Reader, will interpret and decode wiegand data from reader, store the card data to a file, and run a wireless access point.
  * **Raspberry Pi Zero W** - Attached to a Proxmark or other card-writer. It will connect to the wireless access point running from the first Raspberry Pi, run a web server that allows reading and writing of card data.
  * **Battery Source (18650)** - Must support 3A. Can be 12V or under. Will require a boost converter if under 12V. (Low current will result in reduced range of the reader)
  * **Optional - (Depending on power source) DC - DC Boost Converter** - Used to set up battery voltage to 12V if the battery source is under 12V
  * **DC - DC Buck Converter** - Used to step down voltage to 5V for powering the Raspberry Pi Zero W (e.g. https://www.adafruit.com/product/2190)
  * **Wire** - Appropriate gauge for power and wiegand data

## Raspberry Pi (Reader) Setup
  * Install Raspbian Lite on the Raspberry Pi Zero W that will be wired to the Long Range Reader
  * Run the ./setup-reader.sh script from this project **as root**
## Raspberry Pi (Writer) Setup
  * Install Raspbian Lite on the Raspberry Pi Zero W that will be wired to the card writer
  * Run the ./setup-writer.sh script from this project **as root**

## Hardware Setup
  * Connect battery source to DC Boost Converter, stepping up voltage to 12V DC
  * Connect DC Boost Converter output to long range reader Power and Ground (Refer to the reader's manual for information on where to plug the cables into the reader)
  * Connect the DC Buck Converter into the Boost Converter output, stepping down voltage to 5V DC
  * Connect Raspberry Pi Zero W to Buck Converter output. (**5V to Pin 02**, **Ground to Pin 06**)
  * Connect Weigand data cables from Long Range Reader to Raspberry Pi (**Data0 to Pin 8** (GPIO 14), **Data1 to Pin 10** (GPIO 15)
  * For tips on wiring up the HID reader, see the awesome blog post by [Shubs](https://shubs.io/guide-to-building-the-tastic-rfid-thief/)
  
  ![Pin Out](https://www.element14.com/community/servlet/JiveServlet/previewBody/73950-102-11-339300/pi3_gpio.png)
  
  ## How to Use
Once the hardware and software is set up, power on the long range reader. The Raspberry Pi attached to the Long Range Reader should be started first, then the writer. When it boots up, it will automatically set up a wireless access point. Connect to the WiFi network with a laptop or a phone using the details configured in the setup script. Visit the web page **http://192.168.3.100**. Any RFID cards scanned with the reader should automatically populate on the list hosted on the web page. 
From the web page, you can choose a card from your list, press a button and clone to a card, through the attached Proxmark, on-the-fly.
  ![Cloning on the Go](https://raw.githubusercontent.com/Joshua1909/WeaponisedReader/master/card_cloning.png)

###  WIFI Details
    SSID: (as configured in setup)
    WPA Key: (as configured in setup)
    IP Address of Pi Reader: 192.168.3.1
    IP Address of Pi Writer: 192.168.3.100
    
### Web page details
    http://192.168.3.100
  
