# stek-aispatcher
https://github.com/steken/stek-aispatcher

Download "install-aispatcher.sh" https://raw.githubusercontent.com/steken/stek-aispatcher/main/install-aispatcher.sh to your home-folder and run it as root.
This will install a patched version of AIS-catcher in /usr/share/aiscatcher, and run it as a service.


```console
cd
rm install-aispatcher.sh
wget https://raw.githubusercontent.com/steken/stek-aispatcher/main/install-aispatcher.sh
chmod +x install-aispatcher.sh
sudo ./install-aispatcher.sh
```

Edit the config file:
```console
sudo nano /usr/share/aiscatcher/aiscatcher.conf
```

Restart the service:
```console
sudo systemctl restart aiscatcher.service
```

Check status:
```console
systemctl status aiscatcher.service
```


Contributions to:

https://github.com/abcd567a/install-aiscatcher

https://github.com/jvde-github/AIS-catcher

https://aiscatcher.org/
