/*
Copyright 2018 The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"context"
	"flag"
	"os"

	"sigs.k8s.io/sig-storage-lib-external-provisioner/v10/controller"

	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	klog "k8s.io/klog/v2"
)

const (
	ProvisionerName = "nuodb.github.io/noop-provisioner"
)

var (
	kubeconfig = flag.String("kubeconfig", os.Getenv("KUBECONFIG"), "Absolute path to the kubeconfig file. Needs to be set if the provisioner is being run out of cluster.")
)

type noopProvisioner struct{}

var _ controller.Provisioner = &noopProvisioner{}

// Provision creates a storage asset and returns a PV object representing it.
func (p *noopProvisioner) Provision(ctx context.Context, options controller.ProvisionOptions) (*v1.PersistentVolume, controller.ProvisioningState, error) {
	path := "/noop"
	pv := &v1.PersistentVolume{
		ObjectMeta: metav1.ObjectMeta{
			Name:        options.PVName,
			Annotations: map[string]string{},
		},
		Spec: v1.PersistentVolumeSpec{
			PersistentVolumeReclaimPolicy: *options.StorageClass.ReclaimPolicy,
			AccessModes:                   options.PVC.Spec.AccessModes,
			Capacity: v1.ResourceList{
				v1.ResourceName(v1.ResourceStorage): options.PVC.Spec.Resources.Requests[v1.ResourceName(v1.ResourceStorage)],
			},
			PersistentVolumeSource: v1.PersistentVolumeSource{
				HostPath: &v1.HostPathVolumeSource{
					Path: path,
				},
			},
		},
	}
	return pv, controller.ProvisioningFinished, nil
}

// Delete removes the storage asset that was created by Provision represented
// by the given PV.
func (p *noopProvisioner) Delete(ctx context.Context, volume *v1.PersistentVolume) error {
	return nil
}

func main() {
	flag.Parse()
	flag.Set("logtostderr", "true")

	var config *rest.Config
	var err error
	if *kubeconfig != "" {
		klog.Infof("Using supplied kube config %s...", *kubeconfig)
		config, err = clientcmd.BuildConfigFromFlags("", *kubeconfig)
	} else {
		klog.Infof("Building kube config for running in cluster...")
		config, err = rest.InClusterConfig()
	}
	if err != nil {
		klog.Fatalf("Failed to create config: %v", err)
	}
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		klog.Fatalf("Failed to create client: %v", err)
	}

	// Start the provision controller with noop provisioner implementation
	pc := controller.NewProvisionController(clientset, ProvisionerName, &noopProvisioner{})

	// Never stops.
	pc.Run(context.Background())
}
