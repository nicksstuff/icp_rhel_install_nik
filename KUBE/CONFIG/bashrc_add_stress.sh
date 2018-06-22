
  function stresstest()
  {
  echo "Starting busybox";
  echo "then start    yes > /dev/null & ";
  docker run -it --rm busybox
  }

  
