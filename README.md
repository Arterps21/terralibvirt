# terralibvirt

Следует установить все зависимости для работы libvirt.

Отредактировать файл /etc/libvirt/qemu.conf и добавить строчку security_driver = "none"

Обновить сервис.

Через snap установить terraform.

С github скачать плагин по ссылке https://github.com/dmacvicar/terraform-provider-libvirt/releases

В отдельную папку склонировать репозиторий

Изменить ssh ключ в cloud-config на свой публичный

terraform init; plan; apply

Готово
