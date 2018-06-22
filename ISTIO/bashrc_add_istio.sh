
  function istio_helloworld_test()
  {
  echo "TEST HELLOWORLD";
  for i in `seq 1 200000`; do curl http://$(hostname --ip-address):31461/hello; done
  }

  function istio_helloworld_V1()
  {
  echo "Only V1";
  istioctl delete virtualservice helloworld --namespace default
  istioctl create -f ~/INSTALL/ISTIO/vs_100_0.yaml
  }

  function istio_helloworld_BOTH()
  {
  echo "V1 and V2";
  istioctl delete virtualservice helloworld --namespace default
  istioctl create -f ~/INSTALL/ISTIO/vs_50_50.yaml
  }


  function istio_helloworld_V2()
  {
  echo "Only V2";
  istioctl delete virtualservice helloworld --namespace default
  istioctl create -f ~/INSTALL/ISTIO/vs_0_100.yaml
  }


  function istio_helloworld_remove_routingrule()
  {
  echo "Remove Routing Rule";
  istioctl delete virtualservice helloworld --namespace default
  }


  function istio_helloworld_start()
  {
  echo "Starting Hello World";
  istioctl kube-inject -f ~/INSTALL/ISTIO/istio-0.8.0/samples/helloworld/helloworld.yaml -o ~/INSTALL/ISTIO/istio-0.8.0/samples/helloworld/helloworld-istio.yaml
  kubectl create -f ~/INSTALL/ISTIO/istio-0.8.0/samples/helloworld/helloworld-istio.yaml
  }


  function istio_helloworld_stop()
  {
  echo "Stopping Hello World";
  kubectl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/helloworld/helloworld-istio.yaml
  }






  function istio_bookinfo_test()
  {
  echo "TEST HELLOWORLD";
  for i in `seq 1 200000`; do curl http://$(hostname --ip-address):31461/productpage; done
  }


  function istio_bookinfo_V1()
  {
  echo "Only V1";
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-test-v2.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-50-v3.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-v3.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-all-v1.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-test-v2.yaml
  istioctl create -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-all-v1.yaml
  }


  function istio_bookinfo_jason()
  {
  echo "Only JASON on V3";
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-test-v2.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-50-v3.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-v3.yaml
  istioctl create -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-test-v2.yaml
  }


  function istio_bookinfo_BOTH()
  {
  echo "Only JASON on V3";
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-test-v2.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-50-v3.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-v3.yaml
  istioctl create -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-all-v1.yaml
  istioctl create -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-50-v3.yaml

  }


  function istio_bookinfo_V3()
  {
  echo "Only V3";
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-test-v2.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-50-v3.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-v3.yaml
  istioctl create -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-v3.yaml
  }

  function istio_bookinfo_remove_routingrule()
  {
  echo "Reset Routing Rules";
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-test-v2.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-50-v3.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-v3.yaml
  istioctl create -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-all-v1.yaml
  }


  function istio_bookinfo_start()
  {
  echo "Starting Bookinfo";
  istioctl kube-inject -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/kube/bookinfo.yaml -o ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/kube/bookinfo-istio.yaml
  kubectl create -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/kube/bookinfo-istio.yaml
  istioctl create -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/bookinfo-gateway.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-test-v2.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-50-v3.yaml
  istioctl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-reviews-v3.yaml
  istioctl create -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/routing/route-rule-all-v1.yaml
  }


  function istio_bookinfo_stop()
  {
  echo "Stopping Bookinfo";
  kubectl delete -f ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/kube/bookinfo.yaml
  ~/INSTALL/ISTIO/istio-0.8.0/samples/bookinfo/consul/cleanup.sh
  }
