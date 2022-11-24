#!/bin/bash

pgbackrest stanza-create --stanza=db
pgbackrest backup --stanza=db --repo=1
