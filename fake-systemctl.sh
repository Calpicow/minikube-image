#!/bin/bash
case ${1} in
    is-active)
        if [[ ${2} == "firewalld" ]]; then
            echo inactive
            exit 1
        fi

        echo active
        ;;
esac

exit 0
