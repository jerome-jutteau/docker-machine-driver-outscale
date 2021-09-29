package main

import (
	"github.com/docker/machine/libmachine/drivers/plugin"
	"github.com/jerome-jutteau/docker-machine-driver-outscale/pkg/drivers/outscale"
)

func main() {
	plugin.RegisterDriver(outscale.NewDriver("", ""))
}
