# Options

Here is a list supported options for `conflake`,

<script setup>
import { data as options } from './index.data.ts'
</script>

<div>
<ul>
  <li v-for="option of options">
    <a :href="option.url">{{ option.title }}</a>
  </li>
</ul>
 </div>
