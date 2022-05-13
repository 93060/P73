---
# Laboratorium 7 - Zadanie P7.3. 
### Autor: Sebastian Wiktor 
---

### 1. Dockerfile i skrypt pluto.sh
**&ensp;Treść pliku Dockerfile**
```dockerfile
FROM alpine:latest
RUN apk add --no-cache bash
ADD pluto.sh /
RUN chmod 755 /pluto.sh
ENTRYPOINT ["bash", "pluto.sh"] 
```

Dockerfile buduje obraz na podstawie systemu alpine w najnowszej wersji. Następnie instalowany jest pakiet bash, ponieważ nie występuje on w tej wersji Alpine'a. 
Kolejną rzeczą jest dodanie pliku ze skryptem pluto.sh do katalogu głównego kontenera oraz przyznanie uprawnień do tego pliku. ENTRYPOINT określa domyślne 
polecenia dla kontenera, które wykona się po jego uruchomieniu. 

**Skrypt pluto.sh**
```bash
#!/bin/bash
touch /logi/info.log
(printf "Czas uruchomienia kontenera:\n" && date && printf "\nDostepna pamiec hosta:\n" && sed -n "1p" /proc/meminfo && printf "\nLimit pamieci przydzielony kontenerowi w bajtach:\n" && sed -n "1p" /sys/fs/cgroup/memory/memory.limit_in_bytes) > /logi/info.log
```

Skrypt pluto.sh w pierwszej kolejności tworzy plik info.log w katalogu logi, po czym wypisuje w tym pliku czas uruchomienia kontnera (w rzeczywistości jest to czas
który skrypt pluto.sh pobierze podczas wykonywania, więc jest to minimalnie później niż uruchomiono kontener), ilość pamięci hosta oraz limit przydzielonej pamięci
kontenerowi w bajtach. 

### 2. Zbudowanie obrazu lab4docker
**Polecenie** 
```
$ docker build -t lab4docker .
```
**Wynik użytego polecenia** 

![1](https://user-images.githubusercontent.com/103113980/168178792-275116ad-3739-49de-af33-a28b4820b759.png)

### 3. Utworzenie wolumenu RemoteVol

**Polecenie** 
```
$ docker volume create \
	--driver local \
	--opt type=cifs \
	--opt device=//192.168.0.102/logi \
	--opt o=addr=192.168.0.102,username=Seba,password=12345,file_mode=0777,dir_mode=0777 \
	--name RemoteVol
```
**Wynik użytego polecenia** 

![2](https://user-images.githubusercontent.com/103113980/168179030-9d6486ff-795e-4401-a615-734540b96161.png)

Jako, że systemem maszyny macierzystej jest Windows, katalog udostępniany jest poprzez CIFS flagą `--opt type=cifs`. Parametr `--opt device` określa ścieżkę do 
udostępnionego folderu. `--opt o` określa adres IP systemu macierzystego, nazwę oraz hasło użytkownika oraz uprawnienia do folderu.  

**Udostępnienie folderu na systemie macierzystym wraz ze sprawdzeniem adresu IP**

![3](https://user-images.githubusercontent.com/103113980/168179331-d93c18c2-efb2-42f5-99f9-d4b0723b2495.png)

Utworzyłem folder logi na dysku C systemu macierzystego. Następnie poprzez właściwości udostępniłem go w sieci. Ważne jest, aby system macierzysty był widoczny
dla innych urządzeń w sieci lokalnej.

**Aby kontener mógł komunikować się z hostem macierzystym należy zmienić tryb sieci - w tym przypadku na mostkowaną kartę sieciową.**

![image](https://user-images.githubusercontent.com/103113980/168390216-2ed889b4-4859-4b5c-9f1a-28b36ae75fa5.png)


### 4. Uruchomienie kontenera alpine4 

**Polecenie** 
```
$ docker run --name alpine4 -m 512m  -it --mount source=RemoteVol,target=/logi lab4docker
```

**Wynik użytego polecenia** 

![4](https://user-images.githubusercontent.com/103113980/168180101-d879b385-2813-4f61-8e79-43725e66c042.png)

### 5. Potwierdzenie działania wykonanego zadania

**W katalogu logi na systemie macierzystym pojawił się plik** `info.log`

![5](https://user-images.githubusercontent.com/103113980/168180362-f1c9eb5b-a592-4070-a127-6a4a847cbc1b.png)

**Treść pliku** `info.log`

![6](https://user-images.githubusercontent.com/103113980/168180411-97701acf-f62f-49a2-831e-ed2968bf4068.png)

**Wynik polecenia** `docker inspect alpine4`

![7](https://user-images.githubusercontent.com/103113980/168180997-b6388a32-4c1a-44ee-9446-7c96a0f8e8cd.png)

**Potwierdzenie ograniczenia pamięci RAM do 512MB**

![8](https://user-images.githubusercontent.com/103113980/168181055-5dc7aaef-7676-40dd-9dfe-b70cad75d8cc.png)

**Potwierdzenie uruchomienia skryptu pluto.sh przez** `ENTRYPOINT`

![9](https://user-images.githubusercontent.com/103113980/168181117-00e6bb74-a2ae-4713-bb4c-747dca004e8f.png)

Udało się zrealizować zadanie i podpiąć folder z systemu macierzystego jako volume do kontenera. Skrypt pluto.sh wygenerował datę, całkowitą dostępną
pamięć na maszynie hosta oraz limit pamięci jaki został przydzielony kontenerowi. Niestety w tej wersji zadania nie byłem w stanie skorzystać z narzędzia
`CADVISOR` czy polecenia `docker inspect ...`, ponieważ kontener po zdefiniowanym ENTRYPOINT i wykonaniu skryptu pluto.sh kończył działanie z wynikiem 0 (czyli poprawnie się zakończył). Kontener kończył działanie pomimo ustawionych flag `-it` przy jego uruchamianiu (wydaje mi się, że jest to prawidłowe działanie - kontener wykonuje swoje zadanie i kończy pracę). W ramach przetestowania narzędzia `CADVISOR` zbudowałem obraz bez polecenia `ENTRYPOINT`
w pliku Dockerfile, i ręcznie uruchomiłem skrypt `pluto.sh`. Dzięki temu możliwe było podejrzenie pliku `info.log` w środku kontenera. Wynik tych działań
znajduje się poniżej. 

### 6. Wykorzystanie narzędzia `CADVISOR` 

**Uruchomienie zmienionej wersji zadania w kontenerze** `alpine4_1`

![10](https://user-images.githubusercontent.com/103113980/168183439-b7501000-748d-4aac-b1e1-e9b276b5cdd6.png)

Jak widać teraz mamy możliwość wejścia na konsolę w kontenerze. Po uruchomieniu skryptu `pluto.sh` możemy także zobaczyć wygenerowany plik `info.log`. 

**Wynik polecenia** `docker stats alpine4_1`

![14](https://user-images.githubusercontent.com/103113980/168183753-ffc0f393-6b66-413a-8984-42d932561e5b.png)

**Polecenie uruchamiające kontener z CADVISOREM**
```
sudo docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  --privileged \
  --device=/dev/kmsg \
  gcr.io/cadvisor/cadvisor
  ```
**Przedstawienie funkcjonalności CADVISORA**

![11](https://user-images.githubusercontent.com/103113980/168183885-982d5433-2e09-4e8f-9963-cb62eeb3fcd1.png)

Wchodząc w przeglądarkę i wpisując adres `localhost:8080` wchodzimy na stronę narzędzia `CADVISOR`. Widzimy listę z uruchomionymi kontenerami, a także
informacje o systemie hosta, wersję Dockera, ilość obrazów czy ilość kontenerów. Wchodzimy w uruchomiony kontener `alpine4_1`.

![12](https://user-images.githubusercontent.com/103113980/168184146-890d3639-946c-4595-b806-2b78b6c2be50.png)

CADVISOR pozwala monitorować zużycie zasobów (pamięć, CPU) przez kontener, ruch sieciowy czy informację o limicie pamięci lub ilości używanych rdzeni
procesora. Jak widać na powyższym zrzuciue ustawiony jest limit pamięci raz na 512MB. Dzięki narzędziu możemy również zobaczyć listę uruchomionych procesów w kontenerze, błędy czy informacje o systemie plików. 

![13](https://user-images.githubusercontent.com/103113980/168184589-3c4bc11c-9fc9-48cb-be38-85194ca9160e.png)

Wykres, na którym widoczny jest wygenerowany ruch sieciowy w kontenerze. 

---






  








