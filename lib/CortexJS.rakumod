use v6.d;
unit module CortexJS;

use CortexJS::ComputeEngine;

our constant ComputeEngine is export = CortexJS::ComputeEngine;

our sub resources($key) {
    %?RESOURCES{$key}
}