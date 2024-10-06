# Simple Inventory Label Generator

This directory contains a small label generator for the simple inventory system.
It can be used to generate printable labels with QR codes and human readable IDs for a very specifc kind of label blank.
The IDs are generated based on the current date and time to keep them short and unique for a single user.

Run it on systems with Nix and flakes like this: `nix run github:mayjs/simple_inventory`

Provide a base URL for the labels as a command line argument and a PDF with your labels will be generated.
