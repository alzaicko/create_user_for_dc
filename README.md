# Скрипт для заведения пользователей в Windows Domain Controller

Скрипт реализован на PowerShell

## Внимание
Для работы скрипта вам необходимо включить AD PowerShell модуль

Для включения модуля необходимо перейти 
Control Panel > Programs > Turn Windows Features On or Off > Remote Server Administration Tools > Role Administration Tools > AD DS and AD LDS Tools > Active Directory module for Windows PowerShell

![Image alt](https://github.com/alzaicko/create_user_for_dc.git/raw/master/image/image.png)

Так же необходимо обладать учётной записью доменного администратора!!!

## Принцип создания пользователя
Пользователь указывает свои имя и фамилию из которых потом формируются данные.

Так же пользователь указывает пароль который должен быть от 8 до 14 символов,
содержать большие, маленькие буквы, цифры либо спецсимволы.

Если пароль не соответствует таким параметрам то будет предложена возможность использования сгенерированого пароля.

Будет создан пользователь с логином имя.фамилия и будет добавлена почта вида имя.фамилия@domen.com

## Работа скрипта


Пред запуском скрипта необходимо указать переменные:
``` powershell
$dc_server = "<IP or hostname DC server>"   # You primary damain controller
$dc_domain = "<test.local>"                 # You domain
$dc_path = "<path to create user>"          # CN=Users,DC=test,DC=local
$mail_domain = "<exemple.com>"              # user@exemple.com
```
После чего скрипт можно запускать.

После запуска вам будет задан ряд вопросов ответы на которые сформируют данный пользователя и создадут его.

После удачной отработки скрипта будет выведена информация с логином пользователя, его почтой, и если пароль был сгенерирован то выведется пароль, если пароль тот который вводил пользователь строка будет пустой.
