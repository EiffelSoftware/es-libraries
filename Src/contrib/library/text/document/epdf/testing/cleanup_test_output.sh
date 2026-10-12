#!/bin/bash
echo "Cleaning up test_output directory..."
if [ -d "testing/test_output" ]; then
    rm -rf "testing/test_output"
    echo "test_output directory deleted."
else
    echo "test_output directory does not exist."
fi

