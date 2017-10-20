package consul

import (
	"log"
	"time"
)

////////////
// FUNCTIONS
////////////
func polling() {
	log.Printf("Polling ...\n")
	time.Sleep(5 * time.Second)
	polling()
}
