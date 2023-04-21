# Azure Container Instance Demo

## Private vs. Public

~~~ bash
# Define some env variables
prefix=cptdazaci
location=eastus
myip=$(curl ifconfig.io) # Just in case we like to whitelist our own ip.
myobjectid=$(az ad user list --query '[?displayName==`ga`].id' -o tsv) 

# az group delete -n $prefix -y
az deployment sub create -n $prefix -l $location --template-file deploy.bicep -p myobjectid=$myobjectid myip=$myip prefix=$prefix

# Verify if this is a private ACI group (inside a vnet)
az container show -g $prefix -n $prefix --query ipAddress.type # expect private
az container show -g $prefix -n $prefix --query ipAddress.ip # expect private ip

# login into vm
vmid=$(az vm show -g $prefix -n ${prefix}lin --query id -o tsv)
az network bastion ssh -n ${prefix}bastion -g $prefix --target-resource-id $vmid --auth-type aad
curl -I http://app1.cptdazaci.io/ # expect 200 ok from container instance
logout
~~~


### Clean up
~~~ bash
az group delete -n $prefix --yes --no-wait 
~~~

## MISC

### curl

~~~bash
# dns spoofing via curl
curl -v -H"X-Azure-DebugInfo: 1" http://$fdfqdn/azure.html --resolve $fdfqdn:80:$fdip # expect 200 ok
~~~

### wsl time sync
~~~bash
sudo hwclock -s
sudo ntpdate time.windows.com
~~~

### change chmod at wsl

Based on 
- https://stackoverflow.com/questions/46610256/chmod-wsl-bash-doesnt-work
- https://devblogs.microsoft.com/commandline/automatically-configuring-wsl/

~~~bash
sudo cat /etc/wsl.conf
sudo touch /etc/wsl.conf
sudo nano /etc/wsl.conf
~~~

Add
~~~ text
[automount]
options = "metadata"
~~~

~~~bash
# chmod does not work straight away at WSL.
ls -la azbicep/ssh/chpinoto.key # should be -rwxrwxrwx
sudo chmod 600 azbicep/ssh/chpinoto.key
ls -la azbicep/ssh/chpinoto.key # should be -rw------- now
~~~

### github
~~~ bash
gh repo create $prefix --public
git init
git remote remove origin
git remote add origin https://github.com/cpinotossi/$prefix.git
git submodule add https://github.com/cpinotossi/azbicep
git submodule init
git submodule update
git submodule update --init
git status
git add .gitignore
git add *
git commit -m"azure frontdoor private link demo update cptdazfd"
git push origin main
git push --recurse-submodules=on-demand
git rm README.md # unstage
git --help
git config advice.addIgnoredFile false
git pull origin main
git merge 
origin main
git config pull.rebase false
git init
gh repo create cptdafd --public
git remote add origin https://github.com/cpinotossi/cptdafd.git
git status
git add *
git commit -m"Demo of custom domains and multi origin via http. Version with some hick ups which are mentioned inside the readme docs."
git log --oneline --decorate // List commits
git tag -a v1 e1284bf //tag my last commit
git push origin master


git tag //list local repo tags
git ls-remote --tags origin //list remote repo tags
git fetch --all --tags // get all remote tags into my local repo

git log --pretty=oneline //list commits


git checkout v1
git switch - //switch back to current version
co //Push all my local tags
git push origin <tagname> //Push a specific tag
git commit -m"not transient"
git tag v1
git push origin v1
git tag -l
git fetch --tags
git clone -b <git-tagname> <repository-url> 
~~~